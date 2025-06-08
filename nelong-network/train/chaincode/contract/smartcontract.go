package contract

import (
	"bytes"
	"encoding/json"
	"encoding/base64"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

func (s *SmartContract) UploadData(ctx contractapi.TransactionContextInterface, dataID string, dataStringJSON string) error {
	return ctx.GetStub().PutState(dataID, []byte(dataStringJSON))
}

func (s *SmartContract) UploadLargeData(ctx contractapi.TransactionContextInterface, baseKey string, dataStr string) error {
	data := []byte(dataStr)
	const chunkSize = 2 * 1024 * 1024
	totalChunks := (len(data) + chunkSize - 1) / chunkSize

	for i := 0; i < totalChunks; i++ {
		start := i * chunkSize
		end := start + chunkSize
		if end > len(data) {
			end = len(data)
		}
		chunk := data[start:end]
		chunkKey := fmt.Sprintf("%s_chunk_%d", baseKey, i)
		err := ctx.GetStub().PutState(chunkKey, chunk)
		if err != nil {
			return fmt.Errorf("failed to put chunk %d: %v", i, err)
		}
	}

	// 儲存索引資訊
	index := map[string]interface{}{
		"totalChunks": totalChunks,
		"baseKey": baseKey,
	}
	indexBytes, _ := json.Marshal(index)
	return ctx.GetStub().PutState(baseKey+"_index", indexBytes)
}

func (s *SmartContract) ReadLargeData(ctx contractapi.TransactionContextInterface, baseKey string) (string, error) {
	indexBytes, err := ctx.GetStub().GetState(baseKey+"_index")
	if err != nil {
		return "", err
	}

	var index map[string]interface{}
	json.Unmarshal(indexBytes, &index)

	totalChuncks := int(index["totalChunks"].(float64))
	baseKey  = index["baseKey"].(string)

	var fullData []byte
	for i := 0; i < totalChuncks; i++ {
		chunkKey := fmt.Sprintf("%s_chunk_%d", baseKey, i)
		chunk, err := ctx.GetStub().GetState(chunkKey)
		if err != nil {
			return "", fmt.Errorf("failed to get chunk %d: %v", i, err)
		}
		fullData = append(fullData, chunk...)
	}
	return base64.StdEncoding.EncodeToString(fullData), nil
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

func (s *SmartContract) GetDataByQuery(ctx contractapi.TransactionContextInterface, query string) (string, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(query)
	if err != nil {
		return "", err
	}
	defer resultsIterator.Close()

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return "", err
		}

		if bArrayMemberAlreadyWritten {
			buffer.WriteString(",")
		}
		buffer.Write(queryResponse.Value)
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return buffer.String(), nil
}

// 存enclave-server回傳的attestation
type AttestationResponse struct {
	Type string `json:"type"`
	Document struct {
		Pubkey string `json:"public_key"`
		ModelHash string `json:"model_hash"`
		EnclaveConfig string `json:"enclave_config"`
	} `json:"document"`
	Signature string `json:"signature"`
}

type StartTrainingPayload struct {
	Type           string               `json:"type"`
	TrainDomain    string               `json:"trainDomain"`
	InitiatorMSP   string               `json:"initiatorMSP"`
	SessionNbr     string               `json:"sessionNbr"`
	Attestation    AttestationResponse  `json:"attestation"`
}

func (s *SmartContract) StartTraining(ctx contractapi.TransactionContextInterface, payloadString string) error {
	// 取得觸發者的 MSP_ID
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("取得 MSPID 失敗: %v", err)
	}

	var payloadJson StartTrainingPayload
	err = json.Unmarshal([]byte(payloadString), &payloadJson)
	if err != nil {
		return fmt.Errorf("payload 解析失敗: %v", err)
	}

	// 檢查呼叫者是否為 payload 中指定的 initiator
	if clientMSPID != payloadJson.InitiatorMSP {
		return fmt.Errorf("不允許的 MSP: %s, 只有 %s 可以觸發訓練", clientMSPID, payloadJson.InitiatorMSP)
	}

	// 轉換回 byte array 以供事件發送
	payloadBytes, err := json.Marshal(payloadJson)
	if err != nil {
		return fmt.Errorf("payload 序列化失敗: %v", err)
	}

	// 發送 Chaincode Event
	err = ctx.GetStub().SetEvent("StartTraining", payloadBytes)
	if err != nil {
		return fmt.Errorf("發送訓練事件失敗: %v", err)
	}

	dataID := fmt.Sprintf("%s-%s-%s", clientMSPID, payloadJson.SessionNbr, "attestation")
	err = ctx.GetStub().PutState(dataID, payloadBytes)
	if err != nil {
		return fmt.Errorf("Attestation上鏈失敗")
	}
	return nil
}