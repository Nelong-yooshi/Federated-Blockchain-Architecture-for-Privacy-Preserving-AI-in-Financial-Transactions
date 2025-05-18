#!/usr/bin/env bash

ORGS_NUM=${1:-2}
NELONG_NETWORK_HOME=${NELONG_NETWORK_HOME:-${PWD}}
. ${NELONG_NETWORK_HOME}/scripts/envVar.sh $ORGS_NUM

fetchChannelConfig() {
  local ORG=$1
  local CHANNEL=$2
  local OUTPUT=$3

  setGlobals $ORG

  infoln "Fetching the most recent configuration block for the channel"
#   set -x
  peer channel fetch config ${NELONG_NETWORK_HOME}/channel-artifacts/config_block.pb -o localhost:6050 --ordererTLSHostnameOverride orderer.nelong.com -c $CHANNEL --tls --cafile "$ORDERER_CA"
#   { set +x; } 2>/dev/null

  infoln "Decoding config block to JSON and isolating config to ${OUTPUT}"
#   set -x
  configtxlator proto_decode --input ${NELONG_NETWORK_HOME}/channel-artifacts/config_block.pb --type common.Block --output ${NELONG_NETWORK_HOME}/channel-artifacts/config_block.json
  jq .data.data[0].payload.data.config ${NELONG_NETWORK_HOME}/channel-artifacts/config_block.json >"${OUTPUT}"
  res=$?
#   { set +x; } 2>/dev/null
  verifyResult $res "Failed to parse channel configuration, make sure you have jq installed"
}


createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

#   set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output ${NELONG_NETWORK_HOME}/channel-artifacts/original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output ${NELONG_NETWORK_HOME}/channel-artifacts/modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original ${NELONG_NETWORK_HOME}/channel-artifacts/original_config.pb --updated ${NELONG_NETWORK_HOME}/channel-artifacts/modified_config.pb --output ${NELONG_NETWORK_HOME}/channel-artifacts/config_update.pb
  configtxlator proto_decode --input ${NELONG_NETWORK_HOME}/channel-artifacts/config_update.pb --type common.ConfigUpdate --output ${NELONG_NETWORK_HOME}/channel-artifacts/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat ${NELONG_NETWORK_HOME}/channel-artifacts/config_update.json)'}}}' | jq . > ${NELONG_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json
  configtxlator proto_encode --input ${NELONG_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
#   { set +x; } 2>/dev/null
}


signConfigtxAsPeerOrg() {
  ORG=$1
  CONFIGTXFILE=$2
  setGlobals $ORG
#   set -x
  peer channel signconfigtx -f "${CONFIGTXFILE}"
#   { set +x; } 2>/dev/null
}
