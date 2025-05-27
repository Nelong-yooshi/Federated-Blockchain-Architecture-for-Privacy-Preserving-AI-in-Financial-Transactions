#!/usr/bin/env bash

NELONG_NETWORK_HOME=${NELONG_NETWORK_HOME:-${PWD}}
. ${NELONG_NETWORK_HOME}/scripts/envVar.sh

fetchChannelConfig() {
  local CHANNEL=$1
  local OUTPUT=$2

  setGlobals

  infoln "Fetching the most recent configuration block for the channel"
  # set -x
  peer channel fetch config ${BLOCKFILE_PATH}/config_block.pb -o localhost:${ORDERER_LISTEN_PORT} --ordererTLSHostnameOverride ${ORDERER_HOST} -c $CHANNEL --tls --cafile "$ORDERER_CA"
  # { set +x; } 2>/dev/null

  infoln "Decoding config block to JSON and isolating config to ${OUTPUT}"
  # set -x
  configtxlator proto_decode --input ${BLOCKFILE_PATH}/config_block.pb --type common.Block --output ${BLOCKFILE_PATH}/config_block.json
  jq .data.data[0].payload.data.config ${BLOCKFILE_PATH}/config_block.json >"${OUTPUT}"
  res=$?
  # { set +x; } 2>/dev/null
  verifyResult $res "Failed to parse channel configuration, make sure you have jq installed"
}


createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

#   set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output ${BLOCKFILE_PATH}/original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output ${BLOCKFILE_PATH}/modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original ${BLOCKFILE_PATH}/original_config.pb --updated ${BLOCKFILE_PATH}/modified_config.pb --output ${BLOCKFILE_PATH}/config_update.pb
  configtxlator proto_decode --input ${BLOCKFILE_PATH}/config_update.pb --type common.ConfigUpdate --output ${BLOCKFILE_PATH}/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat ${BLOCKFILE_PATH}/config_update.json)'}}}' | jq . > ${BLOCKFILE_PATH}/config_update_in_envelope.json
  configtxlator proto_encode --input ${BLOCKFILE_PATH}/config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
#   { set +x; } 2>/dev/null
}


signConfigtxAsPeerOrg() {
  CONFIGTXFILE=$1
  setGlobals
#   set -x
  peer channel signconfigtx -f "${CONFIGTXFILE}"
#   { set +x; } 2>/dev/null
}
