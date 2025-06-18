package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/slok/go-http-metrics/metrics/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/slok/go-http-metrics/middleware"
	metricsstd "github.com/slok/go-http-metrics/middleware/std"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func initTracerProvider(ctx context.Context, endpoint string) (*sdktrace.TracerProvider, error) {
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
			attribute.String("service.name", "go-otel-demo"),
		),
	)

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)

	otel.SetTracerProvider(tp)
	return tp, nil
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	tr := otel.Tracer("go-otel-demo")
	_, span := tr.Start(ctx, "helloHandler")
	defer span.End()

	// requestCounter.Add(ctx, 1)

	fmt.Fprintln(w, "Hello, OpenTelemetry!")
}

func main() {
	ctx := context.Background()

	otelEndpoint := "otel-gateway-opentelemetry-collector.otel-gateway.svc.cluster.local:4317"

	// Initialize OpenTelemetry tracer provider
	tp, err := initTracerProvider(ctx, otelEndpoint)
	if err != nil {
		log.Fatalf("failed to initialize tracer: %v", err)
	}
	defer func() { _ = tp.Shutdown(ctx) }()

	// Initialize Prometheus recorder
	recorder := prometheus.NewRecorder(prometheus.Config{})

	// Create metrics middleware
	metricsMw := middleware.New(middleware.Config{
		Recorder: recorder,
	})

	// Wrap the helloHandler with metrics and OpenTelemetry
	wrappedHelloHandler := metricsstd.Handler("hello", metricsMw, otelhttp.NewHandler(http.HandlerFunc(helloHandler), "hello"))

	// Set up the mux
	mux := http.NewServeMux()
	mux.Handle("/hello", wrappedHelloHandler)
	mux.Handle("/metrics", promhttp.Handler())

	// Serve
	log.Println("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}