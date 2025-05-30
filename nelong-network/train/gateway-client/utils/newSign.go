package utils

import (
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"fmt"
)
// newSign creates a new Sign instance using the private key from the specified file path.
func NewSign(keyPath string) identity.Sign {
	priviteKeyPEM, err := ReadFirstFile(keyPath)
	if err != nil {
		panic(fmt.Errorf("failed to read private key file: %w", err))
	}

	privateKey, err := identity.PrivateKeyFromPEM(priviteKeyPEM)
	if err != nil {
		panic(err)
	}

	sign, err := identity.NewPrivateKeySign(privateKey)
	if err != nil {
		panic(err)
	}

	return sign
}