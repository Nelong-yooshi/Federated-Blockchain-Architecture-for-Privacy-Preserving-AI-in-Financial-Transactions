package utils

import (
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"fmt"
)

func NewIdentity(certPath string, mspID string) *identity.X509Identity {
	certificatePEM, err := ReadFirstFile(certPath)
	if err != nil {
		panic(fmt.Errorf("failed to read certficate file: %w", err))
	}

	certificate, err := identity.CertificateFromPEM(certificatePEM)
	if err != nil {
		panic(err)
	}

	id, err := identity.NewX509Identity(mspID, certificate)
	if err != nil {
		panic(err)
	}

	return id
}