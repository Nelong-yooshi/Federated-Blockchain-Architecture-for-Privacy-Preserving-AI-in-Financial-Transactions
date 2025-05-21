package utils

import (
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"chaincode_upload_train_data/utils/asset"
	"fmt"
	"encoding/json"
)

func GetDataByID(contract *client.Contract, mspID string, sha256Hash string) asset.TrainData {
	txnDataID := fmt.Sprintf("txn%s%s", mspID, sha256Hash)
	acctDataID := fmt.Sprintf("acct%s%s", mspID, sha256Hash)
	trainDataID := asset.TrainDataID{
		TxnDataID: txnDataID,
		AcctDataID: acctDataID,
	}
	var trainData asset.TrainData
	fmt.Printf("Txn Data ID: %s\n", trainDataID.TxnDataID)
	fmt.Printf("Acct Data ID: %s\n", trainDataID.AcctDataID)
	txnData, err := contract.EvaluateTransaction("GetTxnDataByID", trainDataID.TxnDataID)
	if err != nil {
		panic(fmt.Errorf("error From Fabric:\nGetting Txn Data Error.\n %w", err))
	}
	err = json.Unmarshal(txnData, &trainData.TxnData)
	if err != nil {
		panic(fmt.Errorf("unmarshaling Txn Data Error.\n %w", err))
	}
	acctData, err := contract.EvaluateTransaction("GetAcctDataByID", trainDataID.AcctDataID)
	if err != nil {
		panic(fmt.Errorf("error From Fabric:\nGetting Acct Data Error.\n %w", err))
	}
	err = json.Unmarshal(acctData, &trainData.AcctData)
	if err != nil {
		panic(fmt.Errorf("unmarshaling Acct Data Error.\n %w", err))
	}

	return trainData
}