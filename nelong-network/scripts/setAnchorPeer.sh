#!/usr/bin/env bash

ORGS_NUM=${1:-2}
ORG=$2
CHANNEL_NAME=$3

NELONG_NETWORK_HOME=${NELONG_NETWORK_HOME:-${PWD}}
. ${NELONG_NETWORK_HOME}/scripts/configUpdate.sh $ORGS_NUM



createAnchorPeerUpdate() {
  local ORG=$1
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

  local HOST="peer0.org${ORG}.nelong.com"
  local PORT=$((7051 + (ORG - 1) * 1000))

#   set -x
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json > ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json
  res=$?
#   { set +x; } 2>/dev/null
  verifyResult $res "Channel configuration update for anchor peer failed, make sure you have jq installed"
  
  createConfigUpdate ${CHANNEL_NAME} ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o localhost:6050 --ordererTLSHostnameOverride orderer.nelong.com -c $CHANNEL_NAME -f ${NELONG_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}


setGlobals $ORG

createAnchorPeerUpdate $ORG

updateAnchorPeer 
