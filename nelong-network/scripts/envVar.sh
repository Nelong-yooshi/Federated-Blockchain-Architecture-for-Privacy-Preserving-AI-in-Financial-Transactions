#!/usr/bin/env bash

NELONG_NETWORK_HOME=${NELONG_NETWORK_HOME:-${PWD}}
. ${NELONG_NETWORK_HOME}/scripts/utils.sh
ORGS_NUM=${1:-2}

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${NELONG_NETWORK_HOME}/organizations/ordererOrganizations/nelong.com/tlsca/tlsca.nelong.com-cert.pem

setCaEnv(){
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    export PEER0_ORG${i}_CA=${NELONG_NETWORK_HOME}/organizations/peerOrganizations/org${i}.nelong.com/tlsca/tlsca.org${i}.nelong.com-cert.pem
  done
}

setCaEnv

setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"

  local BASE_PORT=7051
  PORT=$((BASE_PORT + (USING_ORG - 1) * 1000))
  export CORE_PEER_LOCALMSPID="Org${USING_ORG}MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$(eval echo \$PEER0_ORG${USING_ORG}_CA)
  export CORE_PEER_MSPCONFIGPATH="${NELONG_NETWORK_HOME}/organizations/peerOrganizations/org${USING_ORG}.nelong.com/users/Admin@org${USING_ORG}.nelong.com/msp"
  export CORE_PEER_ADDRESS="localhost:${PORT}"

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
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
