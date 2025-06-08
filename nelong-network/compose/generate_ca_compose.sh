#!/usr/bin/env bash

ORGS_NUM=$1
BASE_PORT=7054
OP_BASE_PORT=17054

echo "version: '3.7'
networks:
  nelong:
    name: fabric_nelong

services:
" > compose/compose-ca.yaml

for (( j=1; j<=ORGS_NUM; j++ ))
do
  PORT=$((BASE_PORT + (j - 1) * 1000))
  OP_PORT=$((OP_BASE_PORT + (j - 1) * 1000))

  echo "  ca_org${j}:
    image: hyperledger/fabric-ca:latest
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-org${j}
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=${PORT}
      - FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=0.0.0.0:${OP_PORT}
    ports:
      - \"${PORT}:${PORT}\"
      - \"${OP_PORT}:${OP_PORT}\"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ../organizations/org${j}:/etc/hyperledger/fabric-ca-server
    container_name: ca_org${j}
    networks:
      - nelong
" >> compose/compose-ca.yaml
done

echo "  ca_orderer:
    image: hyperledger/fabric-ca:latest
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-orderer
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=6054
      - FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=0.0.0.0:16054
    ports:
      - "6054:6054"
      - "16054:16054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ../organizations/ordererOrg:/etc/hyperledger/fabric-ca-server
    container_name: ca_orderer
    networks:
      - nelong
" >> compose/compose-ca.yaml