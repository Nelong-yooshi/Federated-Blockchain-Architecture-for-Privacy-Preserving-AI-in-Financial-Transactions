#!/usr/bin/env bash

source scripts/utils.sh

ORGS_NUM=${1:-2}
CHANNEL_NAME=${2:-"mychannel"}
CC_NAME=${3}
CC_SRC_PATH=${4}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"NA"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}

println "executing with the following"
println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"

INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

FABRIC_CFG_PATH=$PWD/configtx/

# import utils
. scripts/envVar.sh $ORGS_NUM
. scripts/ccutils.sh

function checkPrereqs() {
  jq --version > /dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    errorln "jq command not found..."
    errorln
    errorln "Follow the instructions in the Fabric docs to install the prereqs"
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html"
    exit 1
  fi
}

installAllChaincode() {
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    infoln "Installing chaincode on peer0.org${i}..."
    installChaincode $i
  done
}

approveForAllOrgs() {
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    approveForMyOrg $i
    readiness_args=""

    for (( j=1; j<=ORGS_NUM; j++ )); do
      if [ $j -gt 1 ]; then
        readiness_args+=", "
      fi

      if [ $j -le $i ]; then
        readiness_args+="\\\"Org${j}MSP\\\": true"
      else
        readiness_args+="\\\"Org${j}MSP\\\": false"
      fi
    done
        
    checkCommitReadiness $i $readiness_args
  done
}

getAllorgs() {
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    org_args+="$i "
  done
}

queryAllCommitted() {
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    queryCommitted $i
  done
}

#check for prerequisites
checkPrereqs

## package the chaincode
./scripts/packageCC.sh $CC_NAME $CC_SRC_PATH $CC_VERSION 

PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}_${CC_VERSION}.tar.gz)

## Install chaincode on peer0.orgi
installAllChaincode

resolveSequence

## query whether the chaincode is installed
queryInstalled 1

## approve the chaincode for all orgs
approveForAllOrgs

## now that we know for sure both orgs have approved, commit the definition
org_args=""
getAllorgs

commitChaincodeDefinition $org_args

## query on all orgs to see that the definition committed successfully
queryAllCommitted

## Invoke the chaincode - this does require that the chaincode have the 'initLedger'
## method defined
if [ "$CC_INIT_FCN" = "NA" ]; then
  infoln "Chaincode initialization is not required"
else
  chaincodeInvokeInit $org_args
fi

exit 0
