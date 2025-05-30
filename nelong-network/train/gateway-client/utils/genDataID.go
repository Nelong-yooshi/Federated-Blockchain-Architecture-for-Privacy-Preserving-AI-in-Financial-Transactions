package utils

import (
	"crypto/sha256"
	"encoding/pem"
	"fmt"
	"os"
)

func GenDataID(pkeyPath string) string {
	pkey, err := os.ReadFile(pkeyPath)
	if err != nil {
		panic(fmt.Errorf("reading publickey error.\n %w", err))
	}
	pem, _ := pem.Decode(pkey)
	if pem == nil || pem.Type != "PUBLIC KEY" {
		panic("pem file formation error")
	}

	derBytes := pem.Bytes


	sha256Hash := fmt.Sprintf("%x", sha256.Sum256(derBytes))
	fmt.Printf("SHA256:	%s\n", sha256Hash)

	return sha256Hash
}