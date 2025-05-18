#!/usr/bin/env bash

source scripts/utils.sh

CC_NAME=${1}
CC_SRC_PATH=${2}
CC_VERSION=${3}
CC_PACKAGE_ONLY=${4:-false}

println "executing with the following"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"

FABRIC_CFG_PATH=$PWD/configtx/

#User has not provided a name
if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
  fatalln "No chaincode name was provided. Valid call example: ./network.sh packageCC -ccn basic -ccp chaincode/asset-transfer-basic/chaincode-go -ccv 1.0"

# User has not provided a path
elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
  fatalln "No chaincode path was provided. Valid call example: ./network.sh packageCC -ccn basic -ccp chaincode/asset-transfer-basic/chaincode-go -ccv 1.0"


## Make sure that the path to the chaincode exists
elif [ ! -d "$CC_SRC_PATH" ]; then
  fatalln "Path to chaincode does not exist. Please provide different path."
fi

CC_RUNTIME_LANGUAGE=golang

infoln "Vendoring Go dependencies at $CC_SRC_PATH"
pushd $CC_SRC_PATH
GO111MODULE=on go mod vendor
popd
successln "Finished vendoring Go dependencies"

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

packageChaincode() {
  # set -x
  peer lifecycle chaincode package ${CC_NAME}_${CC_VERSION}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  # { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}_${CC_VERSION}.tar.gz)
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

## package the chaincode
packageChaincode

exit 0
