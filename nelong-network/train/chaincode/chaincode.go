package main

import (
	"chaincode/contract"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)


func main() {
	chaincode, err := contractapi.NewChaincode(&contract.SmartContract{})
	if err != nil {
		log.Panicf("error when creating chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("error when starting chaincode: %v", err)
	}
}