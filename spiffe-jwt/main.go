package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

const socketPath = "unix:///spire-agent-socket/socket"

// const socketPath = "unix:///tmp/spire-agent/public/api.sock"

func main() {
	if err := run(context.Background()); err != nil {
		log.Fatal(err)
	}
}

func run(ctx context.Context) error {
	clientOptions := workloadapi.WithClientOptions(workloadapi.WithAddr(socketPath))

	audience := "spire-test-s3"

	jwtSource, err := workloadapi.NewJWTSource(ctx, clientOptions)
	if err != nil {
		return fmt.Errorf("unable to create JWTSource: %w", err)
	}
	defer jwtSource.Close()

	svid, err := jwtSource.FetchJWTSVID(ctx, jwtsvid.Params{
		Audience: audience,
	})
	if err != nil {
		return fmt.Errorf("unable to fetch SVID: %w", err)
	}

	path := "/svid/jwt.txt"
	content := svid.Marshal()

	f, err := os.Create(path)
	if err != nil {
		log.Fatal(err)
	}

	n, err := f.WriteString(content)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("wrote %d bytes\n", n)

	f.Sync()
	return nil

	// fmt.Println(content)
	// return nil
}
