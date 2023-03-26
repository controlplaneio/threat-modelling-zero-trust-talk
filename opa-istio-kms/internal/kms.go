package internal

import (
	"context"
	"errors"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/kms"
	kmsTypes "github.com/aws/aws-sdk-go-v2/service/kms/types"
	"os/signal"
	"syscall"
)

var (
	algorithmSpecs = map[string]kmsTypes.SigningAlgorithmSpec{
		"PS256": kmsTypes.SigningAlgorithmSpecRsassaPssSha256,
		"PS384": kmsTypes.SigningAlgorithmSpecRsassaPssSha384,
		"PS512": kmsTypes.SigningAlgorithmSpecRsassaPssSha512,
		"RS256": kmsTypes.SigningAlgorithmSpecRsassaPkcs1V15Sha256,
		"RS384": kmsTypes.SigningAlgorithmSpecRsassaPkcs1V15Sha384,
		"RS512": kmsTypes.SigningAlgorithmSpecRsassaPkcs1V15Sha512,
		"ES256": kmsTypes.SigningAlgorithmSpecEcdsaSha256,
		"ES384": kmsTypes.SigningAlgorithmSpecEcdsaSha384,
		"ES512": kmsTypes.SigningAlgorithmSpecEcdsaSha256,
	}
)

func GetAlgorithmSpec(alg string) kmsTypes.SigningAlgorithmSpec {
	return algorithmSpecs[alg]
}

type KmsSignerVerifier interface {
	Sign(alg kmsTypes.SigningAlgorithmSpec, msg string) (string, error)
	Verify(alg kmsTypes.SigningAlgorithmSpec, msg string, sig string) error
}

func NewKmsSignerVerifier(keyID string) (k KmsSignerVerifier, err error) {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return
	}

	client := kms.NewFromConfig(cfg)

	k = kmsSignerVerifier{KeyID: keyID, client: client}
	return
}

type kmsSignerVerifier struct {
	KeyID  string
	client *kms.Client
}

func (k kmsSignerVerifier) Sign(alg kmsTypes.SigningAlgorithmSpec, msg string) (signature string, err error) {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	params := &kms.SignInput{
		KeyId:            aws.String(k.KeyID),
		Message:          []byte(msg),
		MessageType:      kmsTypes.MessageTypeRaw,
		SigningAlgorithm: alg,
	}

	resp, err := k.client.Sign(ctx, params)
	if err != nil {
		return
	}

	signature = string(resp.Signature)
	return
}

func (k kmsSignerVerifier) Verify(alg kmsTypes.SigningAlgorithmSpec, msg string, sig string) (err error) {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	params := &kms.VerifyInput{
		KeyId:            aws.String(k.KeyID),
		Message:          []byte(msg),
		MessageType:      kmsTypes.MessageTypeRaw,
		Signature:        []byte(sig),
		SigningAlgorithm: alg,
	}

	resp, err := k.client.Verify(ctx, params)
	if err != nil {
		return
	}

	if !resp.SignatureValid {
		err = errors.New("invalid signature")
	}

	return
}
