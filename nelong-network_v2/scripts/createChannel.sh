#!/usr/bin/env bash

# imports  

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

. scripts/envVar.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
  setGlobals
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi

	configtxgen -profile ChannelUsingRaft -outputBlock "${BLOCKFILE_PATH}/${CHANNEL_NAME}.block" -channelID $CHANNEL_NAME
	res=$?
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	# Poll in case the raft leader is not set yet
	local rc=1     # fail(1) or success(0)
	local COUNTER=1
	infoln "Adding orderers"
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		# set -x
        . scripts/orderer.sh ${CHANNEL_NAME}> /dev/null 2>&1
		res=$?
		# { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  setGlobals
  local rc=1
  local COUNTER=1

  ## Sometimes Join takes time, hence retry
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
  sleep $DELAY
#   set -x
  peer channel join -b "${BLOCKFILE_PATH}/${CHANNEL_NAME}.block" >&log.txt
  res=$?
#   { set +x; } 2>/dev/null
  	let rc=$res
  	COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  verifyResult $res "After $MAX_RETRY attempts, peer0.${ORG_NAME} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  . scripts/setAnchorPeer.sh $CHANNEL_NAME 
}
