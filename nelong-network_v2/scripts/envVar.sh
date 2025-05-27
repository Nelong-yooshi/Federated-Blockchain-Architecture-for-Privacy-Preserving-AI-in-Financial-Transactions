#!/usr/bin/env bash

NELONG_NETWORK_HOME=${NELONG_NETWORK_HOME:-${PWD}}
. ${NELONG_NETWORK_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true

export PEER0_CA="${NODE_PATH}/${DOMAIN_NAME}.com/tlsca/tlsca.${DOMAIN_NAME}.com-cert.pem"

setGlobals() {
  infoln "Using organization ${ORG_NAME}"
  
  export CORE_PEER_LOCALMSPID="${ORG_NAME}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CA
  export CORE_PEER_MSPCONFIGPATH="${ADMIN_PATH}/msp"
  export CORE_PEER_ADDRESS="localhost:${LISTEN_PORT}"

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -ge 4 ]; do
    export CORE_PEER_LOCALMSPID="${1}MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE="${2}"
    export CORE_PEER_MSPCONFIGPATH="${3}/msp"
    export CORE_PEER_ADDRESS="localhost:${4}"
    PEER="peer0.$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]; then
	    PEERS="$PEER"
    else
	    PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=CORE_PEER_TLS_ROOTCERT_FILE
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # Shift the parameters to get the next peer
    shift 4
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
