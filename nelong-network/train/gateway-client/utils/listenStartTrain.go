package utils

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"gateway-client/logger"
	"net/http"
	"os"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

type StartTrainingPayload struct {
	Type            string                `json:"Type"`
	TrainDomain     string                `json:"trainDomain"`
	InitiatorMSP    string                `json:"initiatorMSP"`
	SessionNbr      string                `json:"sessionNbr"`
	Attestation     AttestationResponse   `json:"attestation"`
}

func ListenStartTrainEvent(network *client.Network, ctx context.Context, appCtx *AppContext) {
	events, err := network.ChaincodeEvents(ctx, os.Getenv("CHAINCODE_NAME"))
	if err != nil {
		logger.Log.Errorf("無法啟動事件監聽: %v", err)
	}
	logger.Log.Info("正在監聽事件")
	for {
		select {
		case event := <-events:
			if event.EventName == "StartTraining" {
				logger.Log.Info("收到訓練通知")

				var payload StartTrainingPayload
				err := json.Unmarshal(event.Payload, &payload)
				if err != nil {
					logger.Log.Errorf("解析事件失敗: %v", err)
					continue
				}
				if payload.InitiatorMSP == os.Getenv("MSP_ID") {
					continue // 忽略自己觸發的事件
				}

				fmt.Println(payload)
				fmt.Println(payload.InitiatorMSP)
				fmt.Println(os.Getenv("MSP_ID"))

				pubkey, err := ParseRSAPublicKey(payload.Attestation.Document.Pubkey)
				if err != nil {
					logger.Log.WithError(err).Error("公鑰解析失敗")
					continue
				}

				appCtx.Mu.Lock()
				appCtx.SessionNbr = &payload.SessionNbr
				appCtx.Attestation = &payload.Attestation
				appCtx.Pubkey = pubkey
				appCtx.IsTraining = true
				appCtx.Mu.Unlock()
				logger.Log.Infof("已更新 AppContext, Session: %s", payload.SessionNbr)
				trainDomain := payload.TrainDomain

				data := map[string]string{
					"mspID": os.Getenv("MSP_ID"),
					"sessionNbr": *appCtx.SessionNbr,
				}
				jsonData, _ := json.Marshal(data)
				fmt.Println(trainDomain)
				resp, err := http.Post(trainDomain, "application/json", bytes.NewBuffer(jsonData))
				if err != nil {
					logger.Log.Error("Participate training failed")
					continue
				}
				resp.Body.Close()
				logger.Log.Info("成功參與訓練")
			}
		
		case <-ctx.Done():
			logger.Log.Info("事件監聽結束")
			return
		}
	}
}