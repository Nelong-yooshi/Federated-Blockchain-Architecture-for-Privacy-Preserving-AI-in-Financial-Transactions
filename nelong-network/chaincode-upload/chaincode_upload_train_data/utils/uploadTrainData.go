package utils

import (
	"encoding/json"
	"fmt"
	"time"
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"chaincode_upload_train_data/utils/asset"
)

func UploadTrainData(contract *client.Contract, mspID string,  dataID string, trainData asset.TrainData) {
	start := time.Now()
	var txnDataID = fmt.Sprintf("txn%s%s", mspID, dataID)
	fmt.Printf("\n--> Submit start training data. \n")
	txnDataJson, err := json.Marshal(trainData.TxnData)
	if err != nil {
		panic(fmt.Errorf("marshaling txn data failed.\n %w", err))
	}
	_, err = contract.SubmitTransaction("UploadTrainData", txnDataID, string(txnDataJson))
	if err != nil {
		panic(fmt.Errorf("failed to submit upload txn data transaction.\n %w", err))
	}

	var acctDataID = fmt.Sprintf("acct%s%s", mspID, dataID)
	acctDataJson, err := json.Marshal(trainData.AcctData)
	if err != nil {
		panic(fmt.Errorf("marshaling acct data failed.\n %w", err))
	}
	_, err = contract.SubmitTransaction("UploadTrainData", acctDataID, string(acctDataJson))
	if err != nil {
		panic(fmt.Errorf("submit transaction error.\n %w", err))
	}

	elapsed := time.Since(start)
	fmt.Printf("\n--> Txn data ID: %s\n", txnDataID)
	fmt.Printf("\n--> Acct data ID: %s\n", acctDataID)
	fmt.Printf("\n--> Submit training data successfully. \n")
	fmt.Printf("\n--> Elapsed time: %s\n", elapsed)
}