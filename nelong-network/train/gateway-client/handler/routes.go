package handler

import (
	"io"
	"os"
	"fmt"
	"time"
	"bytes"
	"net/http"
	"encoding/json"

	"github.com/gin-gonic/gin"

	"gateway-client/logger"
	"gateway-client/utils"
)

func RegisterRoutes(r *gin.Engine, ctx *utils.AppContext) {
	r.GET("/", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"message": "Hellow, world!"})
	})

	r.GET("/function_lst", func(c *gin.Context) {
		funcList := map[string][]string{
			"https://gwcs.nemo00407.uk/upload": {
				"檔案路徑",
			},
			"https://gwcs.nemo00407.uk/query": {
				"assetID",
			},
			"https://gwcs.nemo00407.uk/start_train": {},
		}
		c.JSON(http.StatusOK, funcList)
	})

	r.GET("/start_upload", func(c *gin.Context) {
		logger.Log.Info("Receive start train signal")
		logger.Log.Info("Getting public key from enclave server...")
		// 先 post 新的 sesson number 給 enclave-server
		session_nbr := fmt.Sprintf("sess-%d", time.Now().UnixNano())
		data := map[string]string{
			"session_nbr": session_nbr,
		}
		jsonData, _ := json.Marshal(data)

		resp, err := http.Post("http://localhost:5000/new_session", "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			logger.Log.Fatalf("Starting new session failed.")
		}
		defer resp.Body.Close()
		ctx.SessionNbr = &session_nbr
		// 未完成: 要從resp判斷enclave-server是否有創建新session成功

		resp, err = http.Get("http://localhost:5000/attestation")
		if err != nil {
			logger.Log.Fatalf("HTTP request failed: %v", err)
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			logger.Log.Fatalf("Read body failed: %v", err)
		}

		var attestation utils.AttestationResponse
		if err = json.Unmarshal(body, &attestation); err != nil {
			logger.Log.Fatalf("JSON unmarshal failed: %v", err)
		}
		ctx.Attestation = &attestation
		ctx.Pubkey, _ = utils.ParseRSAPublicKey(ctx.Attestation.Document.Pubkey)
		c.JSON(http.StatusOK, gin.H{"message": "Ok"})
	})
	r.POST("/pubkey", func(c *gin.Context) {
		var req struct {
			Pubkey string `json:"pubkey"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			logger.Log.WithError(err).Warn("Pubkey transport error")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Pubkey transport error"})
			return
		}

		logger.Log.WithFields(map[string]interface{}{
			"pubkey": req.Pubkey,
		}).Info("Getting pubkey...")
		
		pubkey := fmt.Sprintf("pubkey: %s", req.Pubkey)
		c.JSON(http.StatusOK, gin.H{"message": pubkey})
	})

	r.POST("/login", func(c *gin.Context) {
		var req struct {
			Username string `json:"username"`
			Password string `json:"password"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			logger.Log.WithError(err).Warn("Login format error")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Form error"})
			return 
		}
		
		logger.Log.WithFields(map[string]interface{}{
			"username": req.Username,
			"ip": 		c.ClientIP(),
		}).Info("Try to login...")

		c.JSON(http.StatusOK, gin.H{"message": "Login successful"})
	})

	r.POST("/upload_data", func(c *gin.Context) {
		var req utils.TrainData

		// 直接upload會錯，要經過start_train
		if ctx.Pubkey == nil {
			logger.Log.Warn("Didn't get public key")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Didn't get public key"})
			return
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			logger.Log.WithError(err).Warn("Training data format error")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Training data format error"})
			return 
		}

		// 建立資料ID
		dataID := fmt.Sprintf("%s-%s", os.Getenv("MSP_ID"), *ctx.SessionNbr)

		// 加密 txn data
		encryptPayload, err := utils.EncryptJSONHybrid(ctx.Pubkey, req.TxnData)
		if err != nil {
			logger.Log.WithError(err).Error("Failed to encrypt data")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to encrypt data"})
			return 
		}

		// 加密 acct data
		acctEncryptPayload, err := utils.EncryptJSONHybrid(ctx.Pubkey, req.AcctData)
		if err != nil {
			logger.Log.WithError(err).Error("Failed to encrypt data")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to encrypt data"})
			return 
		}

		start := time.Now()
		// 上傳txn payload
		utils.UploadTrainData(ctx.Contract, os.Getenv("MSP_ID"), txnDataID, txnEncryptPayload)
		// 上傳acct payload
		utils.UploadTrainData(ctx.Contract, os.Getenv("MSP_ID"), acctDataID, acctEncryptPayload)
		elasped := time.Since(start)
		logger.Log.Info(fmt.Sprintf("Upload to Fabric elasped time: %d", elasped))
		logger.Log.Info("Upload training data successful")

		c.JSON(http.StatusOK, gin.H{"message": "Uploading data successful"})
	})

	r.POST("/get_data", func(c *gin.Context) {
		var req struct {
			Members []string `json:"members"`
			SessionNbr string `json:"sessionNbr"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "invalid member list"})
			return
		}
		
		if req.SessionNbr != *ctx.SessionNbr {
			logger.Log.Error("Session is invalid")
			c.JSON(400, gin.H{"error": "invalid session nbr"})
			return 
		}


		var assetIDList []string

		for _, member := range req.Members {
			assetID := fmt.Sprintf("%s-%s", member, ctx.Attestation.Document.Pubkey)
			assetIDList = append(assetIDList, assetID)
		}
		
	})
}

// attestaion要上鍊
// 