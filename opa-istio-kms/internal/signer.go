package internal

import (
	"github.com/open-policy-agent/opa/bundle"
)

// AwsKmsSigner demonstrates a custom bundle signing implementation.
type AwsKmsSigner struct{}

// GenerateSignedToken demonstrates how to implement the bundle.Signer interface,
// for the purpose of creating custom bundle signing.
func (s *AwsKmsSigner) GenerateSignedToken(files []bundle.FileInfo, sc *bundle.SigningConfig, keyID string) (string, error) {
	signer, err := NewKmsSignerVerifier(sc.Key)
	if err != nil {
		return "", err
	}

	bundleSignature := NewBundleSignature().WithAlgorithm(sc.Algorithm).WithKeyID(sc.Key).WithFiles(files)
	messageToSign, err := bundleSignature.MessageToSign()
	if err != nil {
		return "", err
	}

	signature, err := signer.Sign(GetAlgorithmSpec(sc.Algorithm), messageToSign)
	if err != nil {
		return "", err
	}

	bundleSignature = bundleSignature.WithSignature(signature)

	return bundleSignature.Encoded()
}
