#!/usr/bin/env bash

channel_name=$1
export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH

if [ $ORDERER_CA = "" ]; then
    ./ scripts/utils.sh
    errorln "ORDERER_CA is not set, please use -ocap to set it in the environment variables."
    printHelp "createChannel"
    exit 0
fi
if [ $ORDERER_ADMIN_TLS_SIGN_CERT = "" ]; then
    ./ scripts/utils.sh
    errorln "ORDERER_ADMIN_TLS_SIGN_CERT is not set, please use -oatsp to set it in the environment variables."
    printHelp "createChannel"
    exit 1
fi
if [ $ORDERER_ADMIN_TLS_PRIVATE_KEY = "" ]; then
    ./ scripts/utils.sh
    errorln "ORDERER_ADMIN_TLS_PRIVATE_KEY is not set, please use -oatkp to set it in the environment variables."
    printHelp "createChannel"
    exit 1
fi

osnadmin channel join --channelID ${channel_name} --config-block ./channel-artifacts/${channel_name}.block -o localhost:${ORDERER_ADMIN_LISTEN_PORT} --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >> log.txt 2>&1