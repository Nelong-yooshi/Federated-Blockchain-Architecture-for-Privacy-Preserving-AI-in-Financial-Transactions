echo "version: '3.7'
networks:
  nelong:
    name: fabric_nelong

services:" > ${COMPOSE_CA_PATH}

if [ "$IDENTITY" = "orderer" ]; then
  echo "  ca-${ORG_NAME,,}:
    image: hyperledger/fabric-ca:latest
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-${ORG_NAME,,}
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=${FABRIC_CA_SERVER_PORT}
      - FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=0.0.0.0:${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}
    ports:
      - "${FABRIC_CA_SERVER_PORT}:${FABRIC_CA_SERVER_PORT}"
      - "${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}:${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}"
    command: sh -c 'fabric-ca-server start -b ${CA_ID}:${CA_PW} -d'
    volumes:
      - ${ORG_PATH}:/etc/hyperledger/fabric-ca-server
    container_name: ca-${ORG_NAME,,}
    networks:
      - nelong
" >> ${COMPOSE_CA_PATH}

else
  echo "  ca_${ORG_NAME,,}:
    image: hyperledger/fabric-ca:latest
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-${ORG_NAME,,}
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=${FABRIC_CA_SERVER_PORT}
      - FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=0.0.0.0:${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}
    ports:
      - \"${FABRIC_CA_SERVER_PORT}:${FABRIC_CA_SERVER_PORT}\"
      - \"${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}:${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}\"
    command: sh -c 'fabric-ca-server start -b ${CA_ID}:${CA_PW} -d'
    volumes:
      - ${ORG_PATH}:/etc/hyperledger/fabric-ca-server
    container_name: ca_${ORG_NAME,,}
    networks:
      - nelong
" >> ${COMPOSE_CA_PATH}
fi