echo "version: '3.7'" > ${CLI_COMPOSE_PATH}

if [ "$IDENTITY" != "orderer" ];then 
  echo "services:
  peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com:
      container_name: peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com
      image: hyperledger/fabric-peer:latest
      labels:
        service: hyperledger-fabric
      environment:
        #Generic peer variables
        - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
        - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_nelong
      volumes:
        - ./docker/peercfg:/etc/hyperledger/peercfg
        - ${DOCKER_SOCK}:/host/var/run/docker.sock
        
  " >> ${CLI_COMPOSE_PATH}
fi