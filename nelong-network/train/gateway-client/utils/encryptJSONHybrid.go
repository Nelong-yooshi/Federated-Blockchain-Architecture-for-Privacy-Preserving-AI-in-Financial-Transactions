package utils

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/rsa"
	"crypto"
	"hash"
	"encoding/base64"
	"encoding/json"
	"io"
)


func EncryptJSONHybrid(pubkey *rsa.PublicKey, data any) (*EncryptedPayload, error) {
	// Marshal data into json
	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	// generate 32 bytes AES-256 key
	aesKey := make([]byte, 32)
	if _, err := rand.Read(aesKey); err != nil {
		return nil, err
	}

	// using AES-GCM encrypt
	block, err := aes.NewCipher(aesKey)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	// generate GCM Nonce (12 bytes)
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}

	ciphertext := gcm.Seal(nil, nonce, jsonBytes, nil)

	// Use RSA pubkey encrypt AES key
	encrypedAESKey, err := rsa.EncryptOAEP(
		sha256Hash(),
		rand.Reader,
		pubkey,
		aesKey,
		nil,
	)
	if err != nil {
		return nil, err
	}

	// return struct with base64 encode
	return &EncryptedPayload{
		Key: base64.StdEncoding.EncodeToString(encrypedAESKey),
		Nonce: base64.StdEncoding.EncodeToString(nonce),
		Data: base64.RawStdEncoding.EncodeToString(ciphertext),
	}, nil
}

func sha256Hash() hash.Hash {
	return crypto.SHA256.New()
}