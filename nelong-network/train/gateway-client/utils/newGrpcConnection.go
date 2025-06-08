package utils

import (
	"os"
	"fmt"
	"crypto/x509"

	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

func NewGrpcConnection(tlsCertPath string, gatewayPeer string, peerEndpoint string) *grpc.ClientConn {
	certificatePEM, err := os.ReadFile(tlsCertPath)
	if err != nil {
		panic(fmt.Errorf("failed to read TLS certificate file: %w", err))
	}
	certificate, err := identity.CertificateFromPEM(certificatePEM)
	if err != nil {
		panic(err)
	}

	certPool := x509.NewCertPool()
	certPool.AddCert(certificate)
	transportCredentials := credentials.NewClientTLSFromCert(certPool, gatewayPeer)

	opts := []grpc.DialOption{
		grpc.WithTransportCredentials(transportCredentials),
		grpc.WithDefaultCallOptions(
			grpc.MaxCallRecvMsgSize(50 * 1024 * 1024), // 50MB
			grpc.MaxCallSendMsgSize(50 * 1024 * 1024),
		),
	}

	conn, err := grpc.NewClient(peerEndpoint, opts...)
	if err != nil {
		panic(fmt.Errorf("failed to create gRPC connection: %w", err))
	}

	return conn
}
