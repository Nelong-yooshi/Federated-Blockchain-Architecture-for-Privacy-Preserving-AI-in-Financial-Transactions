echo "version: '3.7'
networks:
  nelong:
    name: fabric_nelong" > ${COMPOSE_PATH}

if [ "$IDENTITY" = "orderer" ]; then
  echo "volumes:
  ${ORG_NAME,,}.${DOMAIN_NAME}.com:
services:
  ${ORG_NAME,,}.${DOMAIN_NAME}.com:
    container_name: ${ORG_NAME,,}.${DOMAIN_NAME}.com
    image: hyperledger/fabric-orderer:latest
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=${LISTEN_PORT}
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
      - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:${CHAINCODE_PORT}
      - ORDERER_OPERATIONS_LISTENADDRESS=${ORG_NAME,,}.${DOMAIN_NAME}.com:${OPERATIONS_LISTEN_PORT}
      - ORDERER_METRICS_PROVIDER=prometheus
    working_dir: /root
    command: orderer
    volumes:
        - ${NODE_PATH}/${DOMAIN_NAME}.com/${ORG_NAME,,}.${DOMAIN_NAME}.com/msp:/var/hyperledger/orderer/msp
        - ${NODE_PATH}/${DOMAIN_NAME}.com/${ORG_NAME,,}.${DOMAIN_NAME}.com/tls/:/var/hyperledger/orderer/tls
        - ${ORG_NAME,,}.${DOMAIN_NAME}.com:/var/hyperledger/production/orderer
    ports:
      - ${LISTEN_PORT}:${LISTEN_PORT}
      - ${CHAINCODE_PORT}:${CHAINCODE_PORT}
      - ${OPERATIONS_LISTEN_PORT}:${OPERATIONS_LISTEN_PORT}
    networks:
      - nelong
" >> ${COMPOSE_PATH}

else
  echo "volumes:
  peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:
services:
  peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:
    container_name: peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com
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
      - CORE_PEER_ID=peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com
      - CORE_PEER_ADDRESS=peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:${LISTEN_PORT}
      - CORE_PEER_LISTENADDRESS=0.0.0.0:${LISTEN_PORT}
      - CORE_PEER_CHAINCODEADDRESS=peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:${CHAINCODE_PORT}
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:${CHAINCODE_PORT}
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:${LISTEN_PORT}
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:${LISTEN_PORT}
      - CORE_PEER_LOCALMSPID=${ORG_NAME}MSP
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp
      - CORE_OPERATIONS_LISTENADDRESS=peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:${OPERATIONS_LISTEN_PORT}
      - CORE_METRICS_PROVIDER=prometheus
      - CHAINCODE_AS_A_SERVICE_BUILDER_CONFIG={"peername":"peer0${ORG_NAME,,}"}
      - CORE_CHAINCODE_EXECUTETIMEOUT=300s
    volumes:
      - ${NODE_PATH}/${DOMAIN_NAME}.com/peers/peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:/etc/hyperledger/fabric
      - peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:/var/hyperledger/production
    working_dir: /root
    command: peer node start
    ports:
      - ${LISTEN_PORT}:${LISTEN_PORT}
      - ${OPERATIONS_LISTEN_PORT}:${OPERATIONS_LISTEN_PORT}
    networks:
      - nelong
" >> ${COMPOSE_PATH}
fi