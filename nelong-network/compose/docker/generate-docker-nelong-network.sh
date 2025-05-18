ORGS_NUM=$1

echo "version: '3.7'
services:
" > compose/docker/docker-compose-nelong-network.yaml

for (( i=1; i<=ORGS_NUM; i++ ))
do
  echo "  peer0.org${i}.nelong.com:
      container_name: peer0.org${i}.nelong.com
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
        
  " >> compose/docker/docker-compose-nelong-network.yaml
done