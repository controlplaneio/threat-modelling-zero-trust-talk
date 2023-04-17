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

var (
	audience = os.Getenv("AUDIENCE")
	path     = os.Getenv("JWT_PATH")
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	jwtHelper, err := NewJwtHelper(ctx)
	if err != nil {
		stop()
		log.Fatalf("failed to create jwt helper: %v", err)
	}
	defer func(jwtHelper JwtHelper) {
		_ = jwtHelper.Close()
	}(jwtHelper)

	jwtStream := make(chan *jwtsvid.SVID, 1)

	getJwtAndStream(ctx, jwtHelper, jwtStream)

	go func() {
		defer close(jwtStream)

		for {
			select {
			case <-time.After(10 * time.Minute):
				getJwtAndStream(ctx, jwtHelper, jwtStream)
			case <-ctx.Done():
				stop()
				log.Println("shutting down")
				os.Exit(0)
			}
		}
	}()

	for jwt := range jwtStream {
		err = os.WriteFile(path, []byte(jwt.Marshal()), 0644)
		if err != nil {
			log.Printf("failed to write jwt: %v\n", err)
		} else {
			log.Printf("updated jwt: %v\n", jwt)
		}
	}
}

func getJwtAndStream(ctx context.Context, jwtHelper JwtHelper, jwtStream chan *jwtsvid.SVID) {
	jwt, err := jwtHelper.GetJwt(ctx, audience)
	if err != nil {
		log.Printf("failed to get jwt: %v", err)
	} else {
		jwtStream <- jwt
	}
}

func NewJwtHelper(ctx context.Context) (helper JwtHelper, err error) {
	jwtSource, err := apiv2.NewJWTSource(ctx)
	if err != nil {
		return
	}

	helper = JwtHelper{jwtSource}
	return
}

type JwtHelper struct {
	source *apiv2.JWTSource
}

func (h JwtHelper) GetJwt(ctx context.Context, audience string) (jwt *jwtsvid.SVID, err error) {
	jwt, err = h.source.FetchJWTSVID(ctx, jwtsvid.Params{
		Audience: audience,
	})
	return
}

func (h JwtHelper) Close() error {
	return h.source.Close()
}
