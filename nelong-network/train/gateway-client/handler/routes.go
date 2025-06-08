package handler

import (
	"io"
	"os"
	"fmt"
	"time"
	"bytes"
	"net/http"
	"encoding/json"
	"encoding/base64"
	"path/filepath"

	"github.com/gin-gonic/gin"

	"gateway-client/logger"
	"gateway-client/utils"
)

func RegisterRoutes(r *gin.Engine, ctx *utils.AppContext) {
	r.GET("/", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})
	r.GET("/latest_predict", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})
	r.GET("/model_efficiency", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})
	r.GET("/train_session", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})
	r.GET("/session_contrib", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})
	r.GET("/data_contrib", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})
	r.GET("/latest_train", func(c *gin.Context) {
		logger.Log.WithField("path", "/").Info("Home Page is requested")
		c.JSON(http.StatusOK, gin.H{"org1": 3, "org2": 5, "org3": 200})
	})

	r.GET("/get_model", func(c *gin.Context) {
		// 假設模型儲存在 ./models/model.json
		modelPath := "model.json"
		filename := filepath.Base(modelPath)

		c.FileAttachment(modelPath, filename)
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

		// 準備 session 編號
		sessionNbr := fmt.Sprintf("sess-%d", time.Now().UnixNano())
		data := map[string]string{
			"sessionNbr": sessionNbr,
		}
		jsonData, _ := json.Marshal(data)
		ctx.Mu.Lock()
		ctx.SessionNbr = &sessionNbr
		ctx.Mu.Unlock()
		// Step 1: 建立新的 session
		resp, err := http.Post("http://tdx-env.nemo00407.uk/new_session", "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			logger.Log.Error("Starting new session failed.")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "session create failed"})
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "enclave did not accept session creation"})
			return
		}

		// Step 2: 取得 attestation
		resp, err = http.Post("http://tdx-env.nemo00407.uk/attestation", "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			logger.Log.Fatalf("HTTP request failed: %v", err)
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			logger.Log.Fatalf("Read body failed: %v", err)
		}

		var attestation utils.AttestationResponse
		if err := json.Unmarshal(body, &attestation); err != nil {
			logger.Log.Fatalf("JSON unmarshal failed: %v", err)
		}

		// Step 3: 組成 StartTrainingPayload
		// 從 Fabric SDK 拿 MSP ID
		clientMSP := os.Getenv("MSP_ID")
		if err != nil {
			logger.Log.Fatalf("取得 MSP ID 失敗: %v", err)
		}
		trainDomain := fmt.Sprintf("%s%s", os.Getenv("TRAIN_DOMAIN"), os.Getenv("TRAIN_REGISTER"))
		payload := struct {
			Type         string                     `json:"type"`
			TrainDomain  string                     `json:"trainDomain"`
			InitiatorMSP string                     `json:"initiatorMSP"`
			SessionNbr   string                     `json:"sessionNbr"`
			Attestation  utils.AttestationResponse  `json:"attestation"`
		}{
			Type         : "Attestation",
			TrainDomain  : trainDomain, // 或從 query / body 傳入
			InitiatorMSP : clientMSP,
			SessionNbr   : sessionNbr,
			Attestation  : attestation,
		}

		pubkey, err := utils.ParseRSAPublicKey(payload.Attestation.Document.Pubkey)
		if err != nil {
			logger.Log.WithError(err).Error("公鑰解析失敗")
			return
		}
		ctx.Mu.Lock()
		ctx.SessionNbr = &payload.SessionNbr
		ctx.Attestation = &payload.Attestation
		ctx.Pubkey = pubkey
		ctx.IsTraining = true
		ctx.Mu.Unlock()
		logger.Log.Info("已更新AppContext, Session: ", sessionNbr)

		payloadBytes, err := json.Marshal(payload)
		if err != nil {
			logger.Log.Fatalf("payload JSON encode 失敗: %v", err)
		}

		// Step 4: 送出 StartTraining 事件到 Fabric
		result, err := ctx.Contract.SubmitTransaction("StartTraining", string(payloadBytes))
		if err != nil {
			logger.Log.Errorf("StartTraining 鏈碼執行失敗: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to submit transaction"})
			return
		}

		logger.Log.Infof("StartTraining 成功送出: %s", string(result))
		ctx.Mu.Lock()
		ctx.IsTraining = true

		data = map[string]string{
			"mspID": os.Getenv("MSP_ID"),
			"sessionNbr": *ctx.SessionNbr,
		}
		ctx.Mu.Unlock()
		jsonData, _ = json.Marshal(data)
		resp, err = http.Post(payload.TrainDomain, "application/json", bytes.NewBuffer(jsonData))

		if err != nil {
			logger.Log.Error("Participate training failed")
			return
		}
		resp.Body.Close()
		logger.Log.Info("成功參與訓練")

		c.JSON(http.StatusOK, gin.H{
			"message":     "Start training triggered",
			"sessionNbr":  sessionNbr,
			"mspID":       clientMSP,
			"attestation": attestation,
		})
	})

	r.GET("/cur-session", func(c *gin.Context) {
		logger.Log.Info("Return current session...")
		c.JSON(http.StatusOK, gin.H{"cur-session": ctx.SessionNbr})
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

// https://gwcs-1.nemo00407.uk/upload_data
	r.POST("/upload_data", func(c *gin.Context) {
		var req utils.TrainData
		ctx.Mu.Lock()
		defer ctx.Mu.Unlock()

		if !ctx.IsTraining || ctx.Pubkey == nil || ctx.SessionNbr == nil {
			logger.Log.Warn("Train runtime didn't start")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Train runtime didn't start"})
			return
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			raw, _ := c.GetRawData()
			logger.Log.WithError(err).Warnf("Training data format error. Raw: %s", string(raw))
			c.JSON(http.StatusBadRequest, gin.H{"error": "Training data format error"})
			return
		}

		dataID := fmt.Sprintf("%s-%s-tdata", os.Getenv("MSP_ID"), *ctx.SessionNbr)

		// 加密後 payload
		encryptPayload, err := utils.EncryptJSONHybrid(ctx.Pubkey, req.TxnData)
		if err != nil {
			logger.Log.WithError(err).Error("Failed to encrypt data")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to encrypt data"})
			return
		}

		start := time.Now()

		jsonPayload, _ := json.Marshal(encryptPayload)
		_, err = ctx.Contract.SubmitTransaction("UploadLargeData", dataID, string(jsonPayload))
		if err != nil {
			logger.Log.WithError(err).Error("Failed to invoke UploadLargeData")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload to chaincode"})
			return
		}

		elapsed := time.Since(start)
		logger.Log.Infof("Upload to Fabric elapsed time: %s", elapsed)
		logger.Log.Info("Upload training data successful")

		c.JSON(http.StatusOK, gin.H{"message": "Uploading data successful"})
	})

	r.GET("/train_contribute", func(c *gin.Context) {
		query := `{"selector":{"type":"attestation"}}`
		res, err := utils.GetDataByQuery(ctx.Contract, query)
		if err != nil {
			logger.Log.Error("Querying data error", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Query error"})
			return
		}

		// 解析回傳的 JSON 陣列
		var records []struct {
			Type         string `json:"type"`
			InitiatorMSP string `json:"initiatorMSP"`
		}

		if err := json.Unmarshal([]byte(res), &records); err != nil {
			logger.Log.WithError(err).Error("Unmarshal error")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Data parsing error"})
			return
		}

		// 建立一個 map 用來記錄每個 MSP 出現次數
		contributions := make(map[string]int)
		for _, record := range records {
			if record.InitiatorMSP != "" {
				contributions[record.InitiatorMSP]++
			}
		}

		c.JSON(http.StatusOK, contributions)
	})

	r.GET("/end_upload", func(c *gin.Context) {
		var memberLstRespone struct {
			MemberLst []string `json:"memberLst"`
		}

		logger.Log.Info("Stop uploading process...")
		// 準備 JSON body
		jsonData, _ := json.Marshal(map[string]string{
			"sessionNbr": *ctx.SessionNbr,
		})
		resp, err := http.Post("https://tdx-env.nemo00407.uk/member_lst", "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			logger.Log.Error("Failed to get member list:", err)
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to get member list"})
			return
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			logger.Log.Fatalf("Read body failed: %v", err)
		}

		if err := json.Unmarshal(body, &memberLstRespone); err != nil {
			logger.Log.Fatalf("JSON unmarshal failed: %v", err)
			return
		}
		ctx.Mu.Lock()
		ctx.SessionMember = &memberLstRespone.MemberLst
		ctx.Mu.Unlock()
		logger.Log.Info(&memberLstRespone.MemberLst)
		logger.Log.Info("End uploading process successfule...")
		c.JSON(http.StatusOK, gin.H{"message": "End uploading process"})
	})

	r.POST("/get_data", func(c *gin.Context) {
		var req struct {
			SessionNbr string `json:"sessionNbr"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid member list"})
			return
		}

		if req.SessionNbr != *ctx.SessionNbr {
			logger.Log.Error("Session is invalid")
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session nbr"})
			return
		}

		var result []string

		for _, member := range *ctx.SessionMember {
			dataID := fmt.Sprintf("%s-%s-tdata", member, req.SessionNbr)

			// 調用 chaincode 的 ReadLargeData，得到 base64 encoded string
			resp, err := ctx.Contract.EvaluateTransaction("ReadLargeData", dataID)
			if err != nil {
				logger.Log.WithError(err).Errorf("Failed to read data for %s", dataID)
				c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to read data: %s", dataID)})
				return
			}

			// 解 base64
			decoded, err := base64.StdEncoding.DecodeString(string(resp))
			if err != nil {
				logger.Log.WithError(err).Error("Failed to decode base64 response")
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid base64 response"})
				return
			}

			result = append(result, string(decoded)) // 這裡回傳原始 JSON string
		}

		logger.Log.Info("Query data successfully")
		logger.Log.Info("Sending data to enclave server...")

		c.JSON(http.StatusOK, gin.H{
			"data": result,
		})
	})

}
