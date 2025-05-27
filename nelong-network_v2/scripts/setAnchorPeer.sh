#!/usr/bin/env bash

CHANNEL_NAME=$1

NELONG_NETWORK_HOME=${NELONG_NETWORK_HOME:-${PWD}}
. ${NELONG_NETWORK_HOME}/scripts/configUpdate.sh



createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $CHANNEL_NAME ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for ${ORG_NAME} on channel $CHANNEL_NAME"

  local HOST="peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com"

#   set -x
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$LISTEN_PORT'}]},"version": "0"}}' ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}config.json > ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}modified_config.json
  res=$?
#   { set +x; } 2>/dev/null
  verifyResult $res "Channel configuration update for anchor peer failed, make sure you have jq installed"
  
  createConfigUpdate ${CHANNEL_NAME} ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}config.json ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}modified_config.json ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o localhost:${ORDERER_LISTEN_PORT} --ordererTLSHostnameOverride ${ORDERER_HOST} -c $CHANNEL_NAME -f ${BLOCKFILE_PATH}/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}


setGlobals
createAnchorPeerUpdate
updateAnchorPeer 
