/*
Program 	   : Fabric Gateway Client
Description    : This client is a interface for user to interact with fabric network by Fabric Gateway API. 
Author         : Nelong
CreateDate     : 2025/05/15

Chage Log
1.0 2025/05/15 : Create
1.0 2025/05/15 : Add utils function
1.1 2025/05/16 : Add upload train data function
1.2 2025/05/17 : Add query train data function 
1.3 2025/05/18 : Fix query data double unmarshal bug
*/

package main

import (
	"chaincode_upload_train_data/utils"
	"fmt"
	"os"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/hash"
	"github.com/joho/godotenv"
)

func main() {
	// load environment variables
	err := godotenv.Load()
	if err != nil {
		panic("Error loading .env file")
	}
	mspID := os.Getenv("MSP_ID")
	certPath := os.Getenv("CERT_PATH")
	keyPath := os.Getenv("KEY_PATH")
	tlsCertPath := os.Getenv("TLS_CERT_PATH")
	peerEndpoint := os.Getenv("PEER_ENDPOINT")
	gatewayPeer := os.Getenv("GATEWAY_PEER")
	chaincodeName := os.Getenv("CHAINCODE_NAME")
	channelName := os.Getenv("CHANNEL_NAME")
	// generating data id by public key
	pkeyPath := "../key/public.pem"
	sha256Hash := utils.GenDataID(pkeyPath)

	// create gRPC connection with
	clientConnection :=utils.NewGrpcConnection(tlsCertPath, gatewayPeer, peerEndpoint)
	if clientConnection == nil {
		panic("failed to create gRPC connection")
	}
	defer clientConnection.Close()

	id := utils.NewIdentity(certPath, mspID)
	sign := utils.NewSign(keyPath)

	// connect to gateway peer
	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithHash(hash.SHA256),
		client.WithClientConnection(clientConnection),
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(15*time.Second),
		client.WithSubmitTimeout(5*time.Second),
		client.WithCommitStatusTimeout(1*time.Minute),
	)
	if err != nil {
		panic(err)
	}
	defer gw.Close()

	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)

	var trainData = utils.GetTrainData(os.Getenv("TXN_DATA_PATH"), os.Getenv("ACCT_DATA_PATH"))
	utils.UploadTrainData(contract, mspID, sha256Hash, trainData)

	queryData := utils.GetDataByID(contract, mspID, sha256Hash)
	fmt.Println(queryData.TxnData)
	fmt.Println(queryData.AcctData)
}









