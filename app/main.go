package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	// "time"

    "github.com/slok/go-http-metrics/metrics/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/slok/go-http-metrics/middleware"
	metricsstd "github.com/slok/go-http-metrics/middleware/std"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var (
	requestCounter metric.Int64Counter
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

func initMetricsProvider(ctx context.Context, endpoint string) (*sdkmetric.MeterProvider, error) {
	conn, err := grpc.NewClient(endpoint, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, err
	}

	exporter, err := otlpmetricgrpc.New(ctx, otlpmetricgrpc.WithGRPCConn(conn))
	if err != nil {
		return nil, err
	}

	provider := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(exporter)),
	)

	otel.SetMeterProvider(provider)
	meter := provider.Meter("go-otel-demo")

	requestCounter, _ = meter.Int64Counter("http_requests_total")

	return provider, nil
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	tr := otel.Tracer("go-otel-demo")
	_, span := tr.Start(ctx, "helloHandler")
	defer span.End()

	requestCounter.Add(ctx, 1)

	fmt.Fprintln(w, "Hello, OpenTelemetry!")
}

func main() {
	ctx := context.Background()

	otelEndpoint := "otel-gateway-opentelemetry-collector.otel-gateway.svc.cluster.local:4317"

	tp, err := initTracerProvider(ctx, otelEndpoint)
	if err != nil {
		log.Fatalf("failed to initialize tracer: %v", err)
	}
	defer func() { _ = tp.Shutdown(ctx) }()

	// mp, err := initMetricsProvider(ctx, otelEndpoint)
	// if err != nil {
	// 	log.Fatalf("failed to initialize metrics: %v", err)
	// }
	// defer func() { _ = mp.Shutdown(ctx) }()

	mux := http.NewServeMux()

	recorder := prometheus.NewRecorder(prometheus.Config{})
	metricsMw := middleware.New(middleware.Config{
		Recorder: recorder,
		IgnoredPaths: []string{"/metrics"},
	})

	mux.Handle("/", otelhttp.NewHandler(http.HandlerFunc(helloHandler), "hello"))
	mux.Handle("/metrics", promhttp.Handler())

	metricsWrapped := metricsstd.Handler("", metricsMw, mux)

	log.Println("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", metricsWrapped))
}
