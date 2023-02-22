package internal

import (
	"fmt"
	"github.com/open-policy-agent/opa/bundle"
)

// AwsKmsVerifier demonstrates a custom bundle verification implementation.
type AwsKmsVerifier struct{}

// VerifyBundleSignature demonstrates how to implement the bundle.Verifier interface,
// for the purpose of creating custom bundle verification.
func (v *AwsKmsVerifier) VerifyBundleSignature(sc bundle.SignaturesConfig, bvc *bundle.VerificationConfig) (map[string]bundle.FileInfo, error) {
	files := make(map[string]bundle.FileInfo)

	if len(sc.Signatures) == 0 {
		return files, fmt.Errorf(".signatures.json: missing signature (expected exactly one)")
	}

	if len(sc.Signatures) > 1 {
		return files, fmt.Errorf(".signatures.json: multiple sgnatures not supported (expected exactly one)")
	}

	for _, signature := range sc.Signatures {
		bundleSignature, err := NewBundleSignature().Parse(signature)
		if err != nil {
			return nil, err
		}

		verifier, err := NewKmsSignerVerifier(bundleSignature.KeyID())
		if err != nil {
			return nil, err
		}

		err = verifier.Verify(GetAlgorithmSpec(bundleSignature.Algorithm()), bundleSignature.SignedMessage, bundleSignature.Signature)
		if err != nil {
			return nil, err
		}

		for key, value := range bundleSignature.FilesAsMap() {
			files[key] = value
		}
	}

	return files, nil
}
