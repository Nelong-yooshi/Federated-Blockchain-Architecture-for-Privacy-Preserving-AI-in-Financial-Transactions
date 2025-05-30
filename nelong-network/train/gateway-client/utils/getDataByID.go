package utils

import (
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"fmt"

	"gateway-client/logger"
)

func GetDataByID(contract *client.Contract, assetID string) string {

	txnData, err := contract.EvaluateTransaction("GetTxnDataByID", assetID)
	if err != nil {
		logger.Log.Error(fmt.Errorf("error From Fabric:\nGetting data Error.\n %w", err))
	}

	return string(txnData)
}