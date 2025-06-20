package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/slok/go-http-metrics/metrics/prometheus"
	"github.com/slok/go-http-metrics/middleware"
	"github.com/slok/go-http-metrics/middleware/std"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/resource"
	
	sdktrace "go.opentelemetry.io/otel/sdk/trace"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func initTracerProvider(ctx context.Context, serviceName string, endpoint string) (*sdktrace.TracerProvider, error) {
	conn, err := grpc.NewClient(endpoint, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, err
	}

	exporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithGRPCConn(conn))
	if err != nil {
		return nil, err
	}

	res, _ := resource.New(ctx,
		resource.WithAttributes(
			attribute.String("service.name", serviceName),
		),
	)

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)

	otel.SetTracerProvider(tp)
	return tp, nil
}

func httpHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	serviceName := os.Getenv("SERVICE_NAME")

	tracer := otel.Tracer(serviceName)
	_, span := tracer.Start(ctx, "handler-span")
	defer span.End()

	log.Printf("INFO: Handling request: %s", r.URL.Path)
	fmt.Fprintf(w, "Hello from %s!\n", serviceName)
}

func main() {
	ctx := context.Background()

	serviceName := os.Getenv("SERVICE_NAME")
	if serviceName == "" {
		serviceName = "otel-go-app"
		os.Setenv("SERVICE_NAME", serviceName)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		os.Setenv("PORT", port)
	}

	endpoint := os.Getenv("OTEL_GATEWAY_ENDPOINT")
	if endpoint == "" {
		endpoint = "otel-gateway-opentelemetry-collector.otel-gateway.svc.cluster.local:4317"
		os.Setenv("OTEL_GATEWAY_ENDPOINT", endpoint)
	}

	// Init OTEL tracing
	tp, err := initTracerProvider(ctx, serviceName, endpoint)
	if err != nil {
		log.Fatalf("ERROR: Server failed: %v", err)
		os.Exit(-1)
	}
	defer tp.Shutdown(ctx)

	// Prometheus + HTTP metrics (go-http-metrics)
	metricsMw := middleware.New(middleware.Config{
		Recorder: prometheus.NewRecorder(prometheus.Config{}),
	})

	mux := http.NewServeMux()

	// Metrics handler (Prometheus scrape)
	mux.Handle("/metrics", promhttp.Handler())

	// Instrumented app handler
	otelWrappedHandler := otelhttp.NewHandler(
		http.HandlerFunc(httpHandler), 
		"otel-handler",
	)
	mwWrappedHandler := std.Handler("root", metricsMw, otelWrappedHandler)

	mux.Handle("/", mwWrappedHandler)

	log.Printf("INFO: Starting server on port %s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("ERROR: Server failed: %v", err)
	}
}
