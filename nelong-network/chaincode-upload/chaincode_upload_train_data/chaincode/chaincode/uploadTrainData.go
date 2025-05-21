package chaincode

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

// UploadTrainData
// GetDataByID


func (s *SmartContract) UploadTrainData(ctx contractapi.TransactionContextInterface, dataID string, dataJson string) error {
	return ctx.GetStub().PutState(dataID, []byte(dataJson))
}

func (s *SmartContract) GetTxnDataByID(ctx contractapi.TransactionContextInterface, dataID string) (string, error) {
	dataJson, err := ctx.GetStub().GetState(dataID)
	if err != nil {
		return "0", fmt.Errorf("failed to read from world state: %v", err)
	}
	if dataJson == nil {
		return "0", fmt.Errorf("the asset %s does not exist", dataID)
	}
	fmt.Println(string(dataJson))
	// var txnData asset.TxnData
	// err = json.Unmarshal(dataJson, &txnData)
	// if err != nil {
	// 	return nil, err
	// }
	
	return string(dataJson) , nil
}

func (s *SmartContract) GetAcctDataByID(ctx contractapi.TransactionContextInterface, dataID string) (string, error) {
	dataJson, err := ctx.GetStub().GetState(dataID)
	if err != nil {
		return "0", fmt.Errorf("failed to read from world state: %v", err)
	}
	if dataJson == nil {
		return "0", fmt.Errorf("the asset %s does not exist", dataID)
	}

	// var acctData asset.AcctData
	// err = json.Unmarshal(dataJson, &acctData)
	// if err != nil {
	// 	return nil, err
	// }
	
	return string(dataJson), nil
}