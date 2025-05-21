package main

import (
	"chaincode_upload_train_data/chaincode/chaincode"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

func main() {
	dataChaincode, err := contractapi.NewChaincode(&chaincode.SmartContract{})
	if err != nil {
		log.Panicf("Error creating upload_train_data chaincode: %v", err)
	}

	if err := dataChaincode.Start(); err != nil {
		log.Panicf("Error starting upload_train_data chaincode: %v", err)
	}
}