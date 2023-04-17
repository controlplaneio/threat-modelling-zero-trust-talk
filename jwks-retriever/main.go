package main

import (
	"context"
	"github.com/spiffe/go-spiffe/v2/bundle/jwtbundle"
	spiffev2 "github.com/spiffe/go-spiffe/v2/spiffeid"
	apiv2 "github.com/spiffe/go-spiffe/v2/workloadapi"
	"log"
	"os"
	"os/signal"
	"syscall"
)

var (
	trustDomain = spiffev2.RequireTrustDomainFromString(os.Getenv("TRUST_DOMAIN"))
	jwksPath    = os.Getenv("JWKS_PATH")
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	bundleHelper, err := NewJwtHelper(ctx, trustDomain)
	if err != nil {
		stop()
		log.Fatalf("failed to create bundle helper: %v", err)
	}
	defer func(bundleHelper BundleHelper) {
		_ = bundleHelper.Close()
	}(bundleHelper)

	bundleStream := make(chan *jwtbundle.Bundle, 1)

	bundle, err := bundleHelper.GetBundle(ctx)
	if err != nil {
		stop()
		log.Fatalf("failed to get bundle: %v", err)
	}

	bundleStream <- bundle

	// TODO: Watch for bundle updates and upload to bucket
	go func() {
		for {
			select {
			case <-ctx.Done():
				stop()
				log.Println("shutting down")
				os.Exit(0)
			}
		}
	}()

	for bundle := range bundleStream {
		bytes, err := bundle.Marshal()
		if err != nil {
			log.Fatal("unable to marshall bundle:", err)
		}

		err = os.WriteFile(jwksPath, bytes, 0644)
		if err != nil {
			log.Fatal("unable to write bundle", err)
		}
	}
}

func NewJwtHelper(ctx context.Context, trustDomain spiffev2.TrustDomain) (helper BundleHelper, err error) {
	jwtSource, err := apiv2.NewJWTSource(ctx)
	if err != nil {
		return
	}

	helper = BundleHelper{jwtSource, trustDomain}
	return
}

type BundleHelper struct {
	source      *apiv2.JWTSource
	trustDomain spiffev2.TrustDomain
}

func (h BundleHelper) GetBundle(ctx context.Context) (bundle *jwtbundle.Bundle, err error) {
	return h.source.GetJWTBundleForTrustDomain(h.trustDomain)
}

func (h BundleHelper) Close() error {
	return h.source.Close()
}
