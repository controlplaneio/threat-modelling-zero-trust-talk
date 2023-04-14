package main

import (
	"context"
	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	apiv2 "github.com/spiffe/go-spiffe/v2/workloadapi"
)

const (
	socketPath = "unix:///spire-agent-socket/socket"
	audience   = "opa-istio"
	path       = "/svid/token"
)

var (
	tickDuration = 5 * time.Minute
	options      = apiv2.WithClientOptions(apiv2.WithAddr(socketPath))
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	jwtSource, err := apiv2.NewJWTSource(ctx, options)
	if err != nil {
		stop()
		log.Fatalf("Unable to create JWTSource: %v\n", err)
	}
	defer jwtSource.Close()

	writeJwt(ctx, jwtSource)

	ticker := time.NewTicker(tickDuration)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			writeJwt(ctx, jwtSource)
		case <-ctx.Done():
			stop()
			log.Println("Shutting down")
			return
		}
	}
}

func writeJwt(ctx context.Context, source *apiv2.JWTSource) {
	jwt, err := source.FetchJWTSVID(ctx, jwtsvid.Params{
		Audience: audience,
	})
	if err != nil {
		log.Printf("Unable to fetch SVID: %v\n", err)
	} else {
		log.Printf("Got jwt: %s\n", jwt.Marshal())
	}

	err = os.WriteFile(path, []byte(jwt.Marshal()), 0644)
	if err != nil {
		log.Printf("Unable to write SVID: %v\n", err)
	}
}
