package main

import (
	"context"
	spiffev2 "github.com/spiffe/go-spiffe/v2/spiffeid"
	apiv2 "github.com/spiffe/go-spiffe/v2/workloadapi"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	jwtSource, err := apiv2.NewJWTSource(ctx)
	if err != nil {
		stop()
		log.Fatal("unable to create jwtSource:", err)
	}
	defer jwtSource.Close()

	trustDomain := spiffev2.RequireTrustDomainFromString(os.Getenv("TRUST_DOMAIN"))
	jwksPath := os.Getenv("JWKS_PATH")

	writeBundle(jwtSource, trustDomain, jwksPath)

	<-ctx.Done()
	log.Println("shutting down")
}

func writeBundle(source *apiv2.JWTSource, trustDomain spiffev2.TrustDomain, jwksPath string) {
	bundle, err := source.GetJWTBundleForTrustDomain(trustDomain)
	if err != nil {
		log.Fatal("unable to fetch bundle:", err)
	}

	bytes, err := bundle.Marshal()
	if err != nil {
		log.Fatal("unable to marshall bundle:", err)
	}

	err = os.WriteFile(jwksPath, bytes, 0644)
	if err != nil {
		log.Fatal("unable to write bundle", err)
	}
}
