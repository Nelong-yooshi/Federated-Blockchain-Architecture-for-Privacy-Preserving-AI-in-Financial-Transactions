package utils

import (
	"encoding/json"
	"fmt"
	"gateway-client/logger"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)


func UploadTrainData(contract *client.Contract, dataID string, data *EncryptedPayload) {
	start := time.Now()
	fmt.Printf("\n--> Submit start training data. \n")
	dataJson, err := json.Marshal(data)
	if err != nil {
		panic(fmt.Errorf("marshaling txn data failed.\n %w", err))
	}
	_, err = contract.SubmitTransaction("UploadData", dataID, string(dataJson))
	if err != nil {
		panic(fmt.Errorf("failed to submit upload txn data transaction.\n %w", err))
	}

	elapsed := time.Since(start)
	logger.Log.Info(fmt.Sprintf("\n-->Uploading data Elapsed time: %s\n", elapsed))
}