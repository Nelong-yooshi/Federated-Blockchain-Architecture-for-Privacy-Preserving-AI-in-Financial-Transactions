package utils

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"gateway-client/logger"
)

func ParseRSAPublicKey(pemStr string) (*rsa.PublicKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		logger.Log.Fatal("Failed to decode PEM block")
		return nil, fmt.Errorf("Failed to decode PEM block")
	}

	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		logger.Log.Fatal("Failed to parse public key: %w", err)
		return nil, fmt.Errorf("Failed to parse public key: %w", err)
	}

	rsaPub, ok := pub.(*rsa.PublicKey)
	if !ok {
		logger.Log.Fatal("Not an RSA public key")
		return nil, fmt.Errorf("Not an RSA public key")
	}

	return rsaPub, nil
}