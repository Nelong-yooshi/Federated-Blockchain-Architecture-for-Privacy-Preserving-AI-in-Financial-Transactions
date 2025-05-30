package contract

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

func (s *SmartContract) UploadData(ctx contractapi.TransactionContextInterface, dataID string, dataStringJSON string) error {
	return ctx.GetStub().PutState(dataID, []byte(dataStringJSON))
}

func (s *SmartContract) GetDataByID(ctx contractapi.TransactionContextInterface, dataID string) (string, error) {
	dataJson, err := ctx.GetStub().GetState(dataID)
	if err != nil {
		return "0", fmt.Errorf("failed to read from world state: %v", err)
	}
	if dataJson == nil {
		return "0", fmt.Errorf("the data %s does not exist", dataID)
	}
	return string(dataJson), nil
} 