package internal

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/open-policy-agent/opa/bundle"
	"strings"
)

func NewBundleSignature() (signature BundleSignature) {
	return
}

type BundleSignature struct {
	Header        header
	Payload       payload
	Signature     string
	SignedMessage string
}

type header struct {
	Algorithm string `json:"alg"`
	KeyID     string `json:"kid"`
}

type payload struct {
	Files []bundle.FileInfo `json:"files"`
}

func (s BundleSignature) WithAlgorithm(alg string) BundleSignature {
	s.Header.Algorithm = alg

	return s
}

func (s BundleSignature) WithKeyID(keyID string) BundleSignature {
	s.Header.KeyID = keyID

	return s
}

func (s BundleSignature) WithFiles(files []bundle.FileInfo) BundleSignature {
	s.Payload.Files = files

	return s
}

func (s BundleSignature) WithSignature(sig string) BundleSignature {
	s.Signature = sig

	return s
}

func (s BundleSignature) MessageToSign() (string, error) {
	encodedHeaders, err := s.Header.encoded()
	if err != nil {
		return "", err
	}

	encodedPayload, err := s.Payload.encoded()
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%s.%s", encodedHeaders, encodedPayload), nil
}

func (s BundleSignature) Encoded() (string, error) {
	message, err := s.MessageToSign()
	if err != nil {
		return "", nil
	}
	signature := encode(s.Signature)

	return fmt.Sprintf("%s.%s", message, signature), nil
}

func (s BundleSignature) Parse(signature string) (BundleSignature, error) {
	parts := strings.Split(signature, ".")

	decodedHeader, err := decode(parts[0])
	if err != nil {
		return s, err
	}

	decodedPayload, err := decode(parts[1])
	if err != nil {
		return s, err
	}

	decodedSignature, err := decode(parts[2])
	if err != nil {
		return s, err
	}

	err = json.Unmarshal(decodedHeader, &s.Header)
	if err != nil {
		return s, err
	}

	err = json.Unmarshal(decodedPayload, &s.Payload)
	if err != nil {
		return s, err
	}

	s.SignedMessage = fmt.Sprintf("%s.%s", parts[0], parts[1])

	s.Signature = string(decodedSignature)

	return s, nil
}

func (s BundleSignature) Algorithm() string {
	return s.Header.Algorithm
}

func (s BundleSignature) KeyID() string {
	return s.Header.KeyID
}

func (s BundleSignature) FilesAsMap() map[string]bundle.FileInfo {
	files := make(map[string]bundle.FileInfo)

	for _, file := range s.Payload.Files {
		files[file.Name] = file
	}

	return files
}

func (h header) encoded() (headers string, err error) {
	jsonHeaders, err := json.Marshal(h)
	if err != nil {
		return
	}

	headers = base64.RawURLEncoding.EncodeToString(jsonHeaders)
	return
}

func (p payload) encoded() (payload string, err error) {
	jsonPayload, err := json.Marshal(p)
	if err != nil {
		return
	}

	payload = base64.RawURLEncoding.EncodeToString(jsonPayload)
	return
}

func encode(s string) string {
	return base64.RawURLEncoding.EncodeToString([]byte(s))
}

func decode(enc string) ([]byte, error) {
	return base64.RawURLEncoding.DecodeString(enc)
}
