package main

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	jwtsvidv2 "github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	apiv2 "github.com/spiffe/go-spiffe/v2/workloadapi"
	"io"
	"log"
	"os"
	"os/signal"
	"syscall"
)

var (
	audience = os.Getenv("AUDIENCE")

	awsRole        = os.Getenv("AWS_ROLE")
	awsSessionName = "session"
	s3Bucket       = os.Getenv("S3_BUCKET")
	s3ObjectKey    = os.Getenv("S3_OBJECT_KEY")

	fifteenMinutes int32 = 900
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	jwtSource, err := apiv2.NewJWTSource(ctx)
	if err != nil {
		log.Fatalf("unable to create jwtSource: %v\n", err)
	}
	defer jwtSource.Close()

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("unable to create aws default config: %v\n", err)
	}

	credentialsProvider := AssumeRoleWithWebIdentityCredentialsProvider{
		jwtSource: jwtSource,
		stsClient: sts.NewFromConfig(cfg),
	}

	s3Client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.Credentials = credentialsProvider
	})

	resp, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s3Bucket),
		Key:    aws.String(s3ObjectKey),
	})
	if err != nil {
		log.Fatalf("unable to get s3 object: %v\n", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("unable to read response from s3: %v\n", err)
	}

	log.Printf("retrieved from s3: %s\n", body)

	select {
	case <-ctx.Done():
		stop()
		log.Println("shutting down")
	}
}

type AssumeRoleWithWebIdentityCredentialsProvider struct {
	jwtSource *apiv2.JWTSource
	stsClient *sts.Client
}

func (p AssumeRoleWithWebIdentityCredentialsProvider) Retrieve(ctx context.Context) (credentials aws.Credentials, err error) {
	jwt, err := p.jwtSource.FetchJWTSVID(ctx, jwtsvidv2.Params{Audience: audience})
	if err != nil {
		log.Printf("failed to retrieve jwt: %v\n", err)
		return
	}

	token := jwt.Marshal()

	assumeRoleWithWebIdentity, err := p.stsClient.AssumeRoleWithWebIdentity(ctx, &sts.AssumeRoleWithWebIdentityInput{
		RoleArn:          &awsRole,
		RoleSessionName:  &awsSessionName,
		WebIdentityToken: &token,
		DurationSeconds:  &fifteenMinutes,
	})
	if err != nil {
		log.Printf("failed to assume role: %v\n", err)
		return
	}

	credentials = aws.Credentials{
		AccessKeyID:     *assumeRoleWithWebIdentity.Credentials.AccessKeyId,
		SecretAccessKey: *assumeRoleWithWebIdentity.Credentials.SecretAccessKey,
		SessionToken:    *assumeRoleWithWebIdentity.Credentials.SessionToken,
		CanExpire:       true,
		Expires:         *assumeRoleWithWebIdentity.Credentials.Expiration,
	}

	return
}
