package utils

import (
	"os"
	"fmt"
	"github.com/gocarina/gocsv"
	"chaincode_upload_train_data/utils/asset"
)





func GetTrainData(txn_file string, acct_file string) asset.TrainData {
	var train_data asset.TrainData
	// load txn data
	txn_data, err := os.OpenFile(txn_file, os.O_RDWR, os.ModePerm)
	if err != nil {
		panic(err)
	}
	defer txn_data.Close()

	if err := gocsv.UnmarshalFile(txn_data, &train_data.TxnData); err != nil {
		panic(err)
	}

	// fmt.Println(string(json_txn_data))
	return train_data
}

func Test() {
	train_data := GetTrainData("../../training_data_hashed.csv", "../../cust_info_hashed.csv")
	fmt.Println(train_data.TxnData)
}
