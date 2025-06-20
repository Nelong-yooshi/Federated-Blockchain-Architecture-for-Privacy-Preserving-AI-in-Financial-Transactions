#!/usr/bin/env bash

ORGS_NUM=$1
BASE_LISTEN_PORT=7051
BASE_CHAINCODE_PORT=7052
BASE_OPERATIONS_LISTEN_PORT=9444

echo "version: '3.7'
networks:
  nelong:
    name: fabric_nelong
volumes:
    orderer.nelong.com:" > compose/compose-nelong-network.yaml

for (( j=1; j<=ORGS_NUM; j++ ))
do
  echo "    peer0.org${j}.nelong.com:" >> compose/compose-nelong-network.yaml
done

echo "services:

  orderer.nelong.com:
    container_name: orderer.nelong.com
    image: hyperledger/fabric-orderer:latest
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=6050
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      # enabled TLS
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_GENERAL_BOOTSTRAPMETHOD=none
      - ORDERER_CHANNELPARTICIPATION_ENABLED=true
      - ORDERER_ADMIN_TLS_ENABLED=true
      - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_ADMIN_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:6053
      - ORDERER_OPERATIONS_LISTENADDRESS=orderer.nelong.com:9443
      - ORDERER_METRICS_PROVIDER=prometheus

      - GRPC_MAX_RECEIVE_MESSAGE_LENGTH=52428800
      - GRPC_MAX_SEND_MESSAGE_LENGTH=52428800
    working_dir: /root
    command: orderer
    volumes:
        - ../organizations/ordererOrganizations/nelong.com/orderers/orderer.nelong.com/msp:/var/hyperledger/orderer/msp
        - ../organizations/ordererOrganizations/nelong.com/orderers/orderer.nelong.com/tls/:/var/hyperledger/orderer/tls
        - orderer.nelong.com:/var/hyperledger/production/orderer
    ports:
      - 6050:6050
      - 6053:6053
      - 9443:9443
    networks:
      - nelong

" >> compose/compose-nelong-network.yaml

for (( j=1; j<=ORGS_NUM; j++ ))
do
  LISTEN_PORT=$((BASE_LISTEN_PORT + (j - 1) * 1000))
  CHAINCODE_PORT=$((BASE_CHAINCODE_PORT + (j - 1) * 1000))
  OPERATIONS_LISTEN_PORT=$((BASE_OPERATIONS_LISTEN_PORT + (j - 1) * 1000))

  echo "  peer0.org${j}.nelong.com:
      container_name: peer0.org${j}.nelong.com
      image: hyperledger/fabric-peer:latest
      labels:
        service: hyperledger-fabric
      environment:
        - FABRIC_CFG_PATH=/etc/hyperledger/peercfg
        - FABRIC_LOGGING_SPEC=INFO
        #- FABRIC_LOGGING_SPEC=DEBUG
        - CORE_PEER_TLS_ENABLED=true
        - CORE_PEER_PROFILE_ENABLED=false
        - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
        - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
        - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
        # Peer specific variables
        - CORE_PEER_ID=peer0.org${j}.nelong.com
        - CORE_PEER_ADDRESS=peer0.org${j}.nelong.com:${LISTEN_PORT}
        - CORE_PEER_LISTENADDRESS=0.0.0.0:${LISTEN_PORT}
        - CORE_PEER_CHAINCODEADDRESS=peer0.org${j}.nelong.com:${CHAINCODE_PORT}
        - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:${CHAINCODE_PORT}
        - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org${j}.nelong.com:${LISTEN_PORT}
        - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org${j}.nelong.com:${LISTEN_PORT}
        - CORE_PEER_LOCALMSPID=Org${j}MSP
        - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
        - CORE_OPERATIONS_LISTENADDRESS=peer0.org${j}.nelong.com:${OPERATIONS_LISTEN_PORT}
        - CORE_METRICS_PROVIDER=prometheus
        - CHAINCODE_AS_A_SERVICE_BUILDER_CONFIG={"peername":"peer0org${j}"}
        - CORE_CHAINCODE_EXECUTETIMEOUT=300s

        # gRPC limit
        - CORE_PEER_GOSSIP_MAXMESSAGESIZE=51200         # 50MB，以 KB 計
        - GRPC_MAX_RECEIVE_MESSAGE_LENGTH=52428800      # 50MB
        - GRPC_MAX_SEND_MESSAGE_LENGTH=52428800         # 50MB
      volumes:
        - ../organizations/peerOrganizations/org${j}.nelong.com/peers/peer0.org${j}.nelong.com:/etc/hyperledger/fabric
        - peer0.org${j}.nelong.com:/var/hyperledger/production
      working_dir: /root
      command: peer node start
      ports:
        - ${LISTEN_PORT}:${LISTEN_PORT}
        - ${OPERATIONS_LISTEN_PORT}:${OPERATIONS_LISTEN_PORT}
      networks:
        - nelong
" >> compose/compose-nelong-network.yaml
done