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

2.0 2025/05/28 : Merg uploading data and train process into same fabric gateway client
*/

package main

import (
	"fmt"
	"os"
	"time"
	"flag"
	"context"
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"

	"gateway-client/handler"
	"gateway-client/logger"
	"gateway-client/utils"

	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/hash"

	"github.com/joho/godotenv"
)

type AttestationResponse struct {
	Document struct {
		Pubkey string `json:"public_key"`
		ModelHash string `json:"model_hash"`
		EnclaveConfig string `json:"enclave_config"`
	} `json:"document"`
	Signature string `json:"signature"`
}

func main() {
	// 定義一個 string flag，名字叫 envFile，預設是 ".env"
    envFile := flag.String("envFile", ".env", "Specify env file to load")
	portArg := flag.String("port", "7080", "Specify port to open")

    // 解析命令列參數
    flag.Parse()

	// load environment variables
	err := godotenv.Load(*envFile)
	if err != nil {
		logger.Log.Error(err)
	}
	mspID := os.Getenv("MSP_ID")
	certPath := os.Getenv("CERT_PATH")
	keyPath := os.Getenv("KEY_PATH")
	tlsCertPath := os.Getenv("TLS_CERT_PATH")
	peerEndpoint := os.Getenv("PEER_ENDPOINT")
	gatewayPeer := os.Getenv("GATEWAY_PEER")
	chaincodeName := os.Getenv("CHAINCODE_NAME")
	channelName := os.Getenv("CHANNEL_NAME")

	// Setting Log and API Register
	isProd := os.Getenv("APP_ENV") == "production"
	logger.InitLogger(isProd)

	r := gin.New()
	
    // CORS 中介層設定，允許所有來源，並設定可用的 HTTP 方法與標頭
    r.Use(cors.New(cors.Config{
        AllowOrigins:     []string{"*"},           // 允許所有來源，實務可換成指定網域
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
        MaxAge:           12 * time.Hour,
    }))

	// add log mid layer
	r.Use(func(c *gin.Context) {
		logger.Log.WithFields(map[string]interface{}{
			"method": c.Request.Method,
			"path": c.Request.URL.Path,
			"ip": c.ClientIP(),
		}).Info("Processing request...")
		c.Next()
	})

	clientConnection := utils.NewGrpcConnection(tlsCertPath, gatewayPeer, peerEndpoint)
	if clientConnection == nil {
		logger.Log.Error("Failed to create gRPC connection")
	}
	defer clientConnection.Close()
	id := utils.NewIdentity(certPath, mspID)
	sign := utils.NewSign(keyPath)
	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithHash(hash.SHA256),
		client.WithClientConnection(clientConnection),
		client.WithEvaluateTimeout(10*time.Second),
		client.WithEndorseTimeout(30*time.Second),
		client.WithSubmitTimeout(20*time.Second),
		client.WithCommitStatusTimeout(2*time.Minute),
	)
	if err != nil {
		logger.Log.Error("Failed to connect with gateway peer")
		logger.Log.Error(err)
	}
	defer gw.Close()
	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)

	ctx := &utils.AppContext{Contract: contract}

	eventCtx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go utils.ListenStartTrainEvent(network, eventCtx, ctx)

	handler.RegisterRoutes(r, ctx)
	
	port := *portArg
	logger.Log.Info(fmt.Sprintf("Server running on: %s", port))
	r.Run(":" + port)
}