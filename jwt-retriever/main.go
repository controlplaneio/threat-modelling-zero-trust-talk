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
	tickDuration = 15 * time.Minute
	options      = apiv2.WithClientOptions(apiv2.WithAddr(socketPath))
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	run(ctx, stop)
}

func run(ctx context.Context, stop context.CancelFunc) {
	jwtSource, err := apiv2.NewJWTSource(ctx, options)
	if err != nil {
		log.Printf("Unable to create JWTSource: %v\n", err)
		stop()
	}
	defer jwtSource.Close()

	writeJwt(ctx, stop, jwtSource)

	ticker := time.NewTicker(tickDuration)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			writeJwt(ctx, stop, jwtSource)
		case <-ctx.Done():
			log.Println("Shutting down")
			return
		}
	}
}

func writeJwt(ctx context.Context, stop context.CancelFunc, source *apiv2.JWTSource) {
	jwt, err := source.FetchJWTSVID(ctx, jwtsvid.Params{
		Audience: audience,
	})
	if err != nil {
		log.Printf("Unable to fetch SVID: %v\n", err)
		stop()
	}

	log.Printf("Got jwt: %s\n", jwt.Marshal())

	err = os.WriteFile(path, []byte(jwt.Marshal()), 0644)
	if err != nil {
		log.Printf("Unable to write SVID: %v\n", err)
		stop()
	}
}
