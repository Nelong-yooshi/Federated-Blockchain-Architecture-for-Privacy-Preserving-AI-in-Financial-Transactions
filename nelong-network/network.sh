#!/usr/bin/env bash
#
# Program Name: nelong-network
# Description: Hyperledger Fabric Network
# Author: nelong
# CreateDate: 2025/05/20
#
# Chage Log:
# 1.0 2025/05/20 : Create
# 1.0 2025/05/20 : Build network
#

VERSION="v1.0.0"
################################################################################
#
#  ##############
#     初始設定 
#  ##############
#  
#   : 設定環境變數、一些需要的路徑與輸出help資訊
#       - PATH : fabric cli的位置
#       - FABRIC_CFG_PATH : configtx.yaml的位置
#       - VERBOSE : 是否複雜輸出
#       - ENV_FILE : 使用者輸入變數檔案
#
################################################################################

sudo -v
ENV_FILE=".network.env"
ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/bin:${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false


# 切換到root目錄，並設置trap讓結束的時候回到原來的目錄
pushd ${ROOTDIR} > /dev/null
trap "popd > /dev/null" EXIT

# 輸出help資訊
. scripts/utils.sh


# Docker Compose 的命令，舊版是 docker-compose、新版是 docker compose
# 這裡會檢查系統上是否有 docker-compose，如果有就使用 docker-compose，否則使用 docker compose
: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi
# 輸出正在使用的容器命令
# infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

################################################################################
#
#  #################
#     移除舊有網路 
#  #################
#  
#   : 將網路還原到原始狀態，已重新開始sample network
#       - clearContainers : 清除不需要的 Container
#       - removeGeneratedImages : 清除運行時 chaincode 產生的 Image
#
################################################################################

# 清理所有 label 是 service=hyperledger-fabric 的容器
# 清理所有 name 為 dev-peer* 的容器
# 清理所有 name 包含 ccaas 的容器（會嘗試 kill）
#   - 2>/dev/null：忽略錯誤訊息
#   - || true：即使指令失敗，也不要讓整個腳本中斷（保持繼續執行）
function clearContainers() {
  infoln "Removing remaining containers"
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter name='dev-peer*') 2>/dev/null || true
  ${CONTAINER_CLI} kill "$(${CONTAINER_CLI} ps -q --filter name=ccaas)" 2>/dev/null || true
}

# 清理所有產生的images
function removeUnwantedImages() {
  infoln "Removing generated chaincode docker images"
  ${CONTAINER_CLI} image rm -f $(${CONTAINER_CLI} images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

# 現在沒有運作了的版本
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

################################################################################
#
#  #################
#     檢查相關依賴 
#  #################
#  
#   : 執行前置檢查，確保你在執行 Hyperledger Fabric 網路之前，
#     所需的 binary 檔案與 Docker image 都正確存在且版本一致。
#       
#
################################################################################
function checkPrereqs() {
  ## 檢查是否已經 clone peer binaries 跟 configuration files
  peer version > /dev/null 2>&1     # 不輸出，會在下面處理錯誤情形

  # 若上面沒有查到版本(沒有裝成功peer binary)
  # 則輸出錯誤資訊
  #   - $?: 前一個指令的退出狀態碼
  #   - -ne: 不等於
  #   - 0: 成功
  #   - 非0: 失敗(例如1, 2, 127)
  if [ $? -ne 0 ]; then
    errorln "Peer binary not found or failed to execute..."
    errorln
    errorln "Make sure the Fabric binaries are installed and added to your PATH."
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi

  # 把你本機的 peer binary 版本（LOCAL_VERSION）和 hyperledger/fabric-peer:latest 
  # 這個 Docker image 裡的 peer 版本（DOCKER_IMAGE_VERSION）抓出來比較
  # 如果版本不一致，會顯示警告訊息（但不會中斷腳本）
  #     - peer version 會執行 Fabric 的 peer CLI 工具，輸出版本資訊，例如：
  #         ```
  #         peer:
  #             Version: 2.5.12
  #             Commit SHA: ...
  #         ```
  #     - 用 sed 把輸出裡「開頭是 Version:」這一行抓出來並取代為純版本號
  LOCAL_VERSION=$(peer version | sed -ne 's/^ Version: //p')
  DOCKER_IMAGE_VERSION=$(${CONTAINER_CLI} run --rm hyperledger/fabric-peer:latest peer version | sed -ne 's/^ Version: //p')

  infoln "LOCAL_VERSION=$LOCAL_VERSION"
  infoln "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    warnln "Local fabric binaries and docker images are out of sync. This may cause problems."
  fi

  # 不可用版本
  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    infoln "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
    fi

    infoln "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
    fi
  done

  ## 檢查 fabric-ca
  fabric-ca-client version > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    errorln "fabric-ca-client binary not found.."
    errorln
    errorln "Follow the instructions in the Fabric docs to install the Fabric Binaries:"
    errorln "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
  fi
  CA_LOCAL_VERSION=$(fabric-ca-client version | sed -ne 's/ Version: //p')
  CA_DOCKER_IMAGE_VERSION=$(${CONTAINER_CLI} run --rm hyperledger/fabric-ca:latest fabric-ca-client version | sed -ne 's/ Version: //p' | head -1)
  infoln "CA_LOCAL_VERSION=$CA_LOCAL_VERSION"
  infoln "CA_DOCKER_IMAGE_VERSION=$CA_DOCKER_IMAGE_VERSION"

  if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
    warnln "Local fabric-ca binaries and docker images are out of sync. This may cause problems."
  fi
}

################################################################################
#
#  ##############
#     建立組織 
#  ##############
#  
#   : 恩對建立組織。然後建立組織之前，會先建立組織的憑證和金鑰，並依此建立!!!
#     這邊需要注意的是，再啟動 Hyperledger Fabric 網路之前，
#     需要先建立組織的憑證和金鑰，這些憑證和金鑰會被用來驗證組織的身份。
#     這邊會使用 Fabric CA 來建立組織的憑證和金鑰。
#     適用於生產環境使用的 CA 服務:
#         - CA 設定檔：organizations/fabric-ca/
#         - 身分註冊與登錄腳本：registerEnroll.sh
#         - 生成資料會放到 organizations/ordererOrganizations/ 等資料夾
#       
#
################################################################################

function createOrgs() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  # 使用 Fabric CA 建立加密材料
  infoln "Generating certificates using Fabric CA"
  # 先根據組織數創建相對應的 .yaml 以配置 docker
  . compose/generate_ca_compose.sh "$ORGS_NUM"
  ${CONTAINER_CLI_COMPOSE} -f compose/$COMPOSE_FILE_CA -f compose/$COMPOSE_FILE_CA up -d 2>&1

  . organizations/registerEnroll.sh

  # 一直睡以確保已建立 CA 文件
  while :
  do
    if [ ! -f "organizations/org1/tls-cert.pem" ]; then
      sleep 1
    else
      break
    fi
  done

  # 在進行註冊和登記呼叫之前，一直睡以確保 CA 服務已初始化並可以接受請求
  #   - 設定 Fabric CA client 的工作目錄（會在這裡產生證書檔等）
  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.nelong.com/
  COUNTER=0
  rc=1

  while [[ $rc -ne 0 && $COUNTER -lt $MAX_RETRY ]]; do
    sleep 1
    # set -x
    fabric-ca-client getcainfo -u https://admin:adminpw@localhost:7054 --caname ca-org1 --tls.certfiles "${PWD}/organizations/org1/ca-cert.pem"
    res=$?
  # { set +x; } 2>/dev/null
  rc=$res  # Update rc
  COUNTER=$((COUNTER + 1))
  done
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    infoln "Creating Org${i} Identities"
    createOrg ${i} "${orgs_names[$((i - 1))]}"
  done

  infoln "Creating Orderer Org Identities"
  createOrderer
  # docker rm -f $(docker ps -a -q)
  infoln "Generating CCP files for All Orgs"
  ./organizations/ccp-generate.sh "$ORGS_NUM"
}

################################################################################
#
#  ##############
#     來搞網路 
#  ##############
#  
#   : 生成創世區塊（genesis block） 並 啟動網路節點（peer 和 orderer）。
#     然後就twelve!!!!!!!!!!!!!!!!!!!!
#     我們要:
#     1. 使用 configtxgen 工具建立創世區塊（genesis block）
#         - 設定檔中包含一個叫 ChannelUsingRaft 的 profile，它會描述整個應用通道的結構（哪幾個組織，哪個共識機制等）
#         - 每個組織在這裡也會指定它們的 MSP（Membership Service Provider）資料夾，用來建構整個通道的「信任根」
#     2. 請忽略的警告訊息
#         - 像 ```[bccsp] GetDefault -> WARN 001``` 是常見警告，通常不影響正常操作，可以忽略
#         - 「intermediate certs」相關訊息也可以略過，因為這個測試環境並沒用中繼憑證
#     3. 使用 Docker Compose 啟動整個網路
#       
#
################################################################################

function networkUp() {
  . ./configtx/generate-configtx.sh
  checkPrereqs

  # generate artifacts if they don't exist
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
  fi

  . ./compose/generate-nelong-network.sh "$ORGS_NUM"
  . ./compose/docker/generate-docker-nelong-network.sh "$ORGS_NUM"
  . ./compose/generate-couch.sh "$ORGS_NUM"

  COMPOSE_FILES="-f compose/${COMPOSE_FILE_BASE} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"
  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f compose/${COMPOSE_FILE_COUCH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_COUCH}"
  fi


  DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} up -d 2>&1

  $CONTAINER_CLI ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

# 呼叫 script 以創建channel
function createChannel() {
  # 啟動網路如果網路尚未啟動
  bringUpNetwork="false"

  # local bft_true=$1

  # 檢查 docker 是否啟動
  if ! $CONTAINER_CLI info > /dev/null 2>&1 ; then
    fatalln "$CONTAINER_CLI network is required to be running to create a channel"
  fi

  # 列出目前已啟動的 Hyperledger 相關容器
  CONTAINERS=($($CONTAINER_CLI ps | grep hyperledger/ | awk '{print $2}'))
  len=$(echo ${#CONTAINERS[@]})

  if [[ $len -ge 4 ]] && [[ ! -d "organizations/peerOrganizations" ]]; then
    echo "Bringing network down to sync certs with containers"
    networkDown
  fi

  [[ $len -lt 4 ]] || [[ ! -d "organizations/peerOrganizations" ]] && bringUpNetwork="true" || echo "Network Running Already"

  if [ $bringUpNetwork == "true"  ]; then
    infoln "Bringing up network"
    networkUp
  fi

  # 前面都在確定 network 起來而已，只有這一步真的在做事...
  scripts/createChannel.sh $ORGS_NUM $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE # $bft_true
}


## 呼叫 script 將鏈碼部署到通道
function deployCC() {
  scripts/deployCC.sh $ORGS_NUM $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}

## 呼叫 script 將鏈碼部署到通道
# function deployCCAAS() {
#   scripts/deployCCAAS.sh $ORGS_NUM $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CCAAS_DOCKER_RUN $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE $CCAAS_DOCKER_RUN

#   if [ $? -ne 0 ]; then
#     fatalln "Deploying chaincode-as-a-service failed"
#   fi
# }

## 呼叫 script 以打包鏈碼
function packageChaincode() {
  infoln "Packaging chaincode"
  if [ "$CC_SRC_PATH" == "" ]; then
    errorln "Chaincode source path not provided. Use -ccp <chaincode_source_path> to specify the chaincode source path."
    printHelp $MODE
    exit 1
  fi
  scripts/packageCC.sh $CC_NAME $CC_SRC_PATH $CC_VERSION

  if [ $? -ne 0 ]; then
    fatalln "Packaging the chaincode failed"
  fi

}

## 呼叫 script 列出 peer 上已安裝提交的鏈代碼
function listChaincode() {

  # export FABRIC_CFG_PATH=${PWD}/config

  . scripts/envVar.sh $ORGS_NUM
  . scripts/ccutils.sh

  setGlobals $ORG

  println
  queryInstalledOnPeer
  println

  listAllCommitted

}

## 呼叫 script 以 invoke 
function invokeChaincode() {

  # export FABRIC_CFG_PATH=${PWD}/config

  . scripts/envVar.sh $ORGS_NUM
  . scripts/ccutils.sh

  setGlobals $ORG

  chaincodeInvoke $ORGS_NUM $ORG $CHANNEL_NAME $CC_NAME $CC_INVOKE_CONSTRUCTOR

}

## 呼叫 script 以 query chaincode 
function queryChaincode() {

  # export FABRIC_CFG_PATH=${PWD}/config
  
  . scripts/envVar.sh $ORGS_NUM
  . scripts/ccutils.sh

  setGlobals $ORG

  chaincodeQuery $ORG $CHANNEL_NAME $CC_NAME $CC_QUERY_CONSTRUCTOR

}


################################################################################
#
#  ##############
#     拆除網路 
#  ##############
#  
#   : 就拆阿
#       
#
################################################################################
function networkDown() {
  COMPOSE_BASE_FILES="-f compose/${COMPOSE_FILE_BASE} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"
  COMPOSE_CA_FILES="-f compose/${COMPOSE_FILE_CA} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_CA}"
  COMPOSE_COUCH_FILES="-f compose/${COMPOSE_FILE_COUCH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_COUCH}"
  COMPOSE_FILES="${COMPOSE_BASE_FILES} ${COMPOSE_COUCH_FILES} ${COMPOSE_CA_FILES}"


  if [ "${CONTAINER_CLI}" == "docker" ]; then
    DOCKER_SOCK=$DOCKER_SOCK ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} down --volumes --remove-orphans
  else
    fatalln "Container CLI  ${CONTAINER_CLI} not supported"
  fi

  # COMPOSE_FILE_BASE=$temp_compose
  local i
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # 移除 volume
    ${CONTAINER_CLI} volume rm docker_orderer.nelong.com
    for ((i=1; i<=ORGS_NUM; i++)); do
        ${CONTAINER_CLI} volume rm docker_peer0.org${i}.nelong.com
    done
    # 清除 chaincode 容器、鏡像
    clearContainers
    removeUnwantedImages
    # 移除 genesis block、組織資料、CA 資料庫
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
    ## CA 資料庫
    for ((i=1; i<=ORGS_NUM; i++)); do
        ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c "cd /data && rm -rf organizations/org${i}/msp organizations/org${i}/tls-cert.pem organizations/org${i}/ca-cert.pem organizations/org${i}/IssuerPublicKey organizations/org${i}/IssuerRevocationPublicKey organizations/org${i}/fabric-ca-server.db"
    done
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/ordererOrg/msp organizations/ordererOrg/tls-cert.pem organizations/ordererOrg/ca-cert.pem organizations/ordererOrg/IssuerPublicKey organizations/ordererOrg/IssuerRevocationPublicKey organizations/ordererOrg/fabric-ca-server.db'
    
    # script artifacts
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  fi

  # 移除舊有資料夾
  for ((i=1; i<=ORGS_NUM; i++)); do
    sudo rm -rf "organizations/org${i}"
  done
  # sudo rm -rf organizations/ordererOrg
}

################################################################################
#
#  ###########
#     cc
#  ###########
#
#   : 這邊是用來處理鏈碼的參數設定
#       
#       
#       
#
#################################################################################

function installChaincodeForOrg() {
  if [ "$ORG" == "" ]; then
    errorln "Organization not provided. Use -org <org_number> to specify the organization."
    printHelp $MODE
    exit 1
  fi

  infoln "Installing chaincode on channel '${CHANNEL_NAME}'"
  . ./scripts/envVar.sh $ORGS_NUM
  . ./scripts/ccutils.sh
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}_${CC_VERSION}.tar.gz)
  installChaincode $ORG
}

function queryInstalledForOrg() {
  if [ "$ORG" == "" ]; then
    errorln "Organization not provided. Use -org <org_number> to specify the organization."
    printHelp $MODE
    exit 1
  fi

  infoln "Querying installed chaincode on channel '${CHANNEL_NAME}'"
  . ./scripts/envVar.sh $ORGS_NUM
  . ./scripts/ccutils.sh
  setGlobals $ORG
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}_${CC_VERSION}.tar.gz)
  resolveSequence
  queryInstalled $ORG
}

function approveForOrg() {
  if [ "$ORG" == "" ]; then
    errorln "Organization not provided. Use -org <org_number> to specify the organization."
    printHelp $MODE
    exit 1
  fi
  if [ "$CHANNEL_NAME" == "" ]; then
    errorln "Channel name not provided. Use -c <channel_name> to specify the channel name."
    printHelp $MODE
    exit 1
  fi

  infoln "Approving chaincode for channel '${CHANNEL_NAME}'"
  if [ "$CC_INIT_FCN" = "" ]; then
    INIT_REQUIRED=""
  else
    INIT_REQUIRED="--init-required"
  fi
  if [ "$CC_END_POLICY" = "" ]; then
    CC_END_POLICY=""
  else
    CC_END_POLICY="--signature-policy $CC_END_POLICY"
  fi
  if [ "$CC_COLL_CONFIG" = "" ]; then
    CC_COLL_CONFIG=""
  else
    CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
  fi


  . ./scripts/envVar.sh $ORGS_NUM
  . ./scripts/ccutils.sh
  setGlobals $ORG
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}_${CC_VERSION}.tar.gz)
  approveForMyOrg $ORG
}

function CommitChaincodeDefinitionForOrg() {
  if [ "$CHANNEL_NAME" == "" ]; then
    errorln "Channel name not provided. Use -c <channel_name> to specify the channel name."
    printHelp $MODE
    exit 1
  fi
  infoln "Make Sure all OrgsDone and Committing chaincode Definition"
  if [ "$CC_INIT_FCN" = "" ]; then
    INIT_REQUIRED=""
  else 
    INIT_REQUIRED="--init-required"
  fi
  if [ "$CC_END_POLICY" = "" ]; then
    CC_END_POLICY=""
  else
    CC_END_POLICY="--signature-policy $CC_END_POLICY"
  fi
  if [ "$CC_COLL_CONFIG" = "" ]; then
    CC_COLL_CONFIG=""
  else
    CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
  fi
  . ./scripts/envVar.sh $ORGS_NUM
  . ./scripts/ccutils.sh

  org_args=""
  local i
  for (( i=1; i<=ORGS_NUM; i++ )); do
    org_args+="$i "
  done

  setGlobals $ORG
  commitChaincodeDefinition $org_args
}

function queryCommittedForOrg() {
  if [ "$CHANNEL_NAME" == "" ]; then
    errorln "Channel name not provided. Use -c <channel_name> to specify the channel."
    printHelp $MODE
    exit 1
  fi
  if [ "$ORG" == "" ]; then
    errorln "Organization not provided. Use -org <org_number> to specify the organization."
    printHelp $MODE
    exit 1
  fi

  infoln "Committing chaincode on channel '${CHANNEL_NAME}'"
  . ./scripts/envVar.sh $ORGS_NUM
  . ./scripts/ccutils.sh
  DELAY=$CLI_DELAY
  setGlobals $ORG
  queryCommitted $ORG
}


################################################################################
#
#  ###########
#     開搞 
#  ###########
#  
#   : 設定 args 代表的參數設定
#       - shift: 把參數列往左移一位。也就是說 $2 變成 $1，以此類推。
#       - 目的是每次都 shift，下次直接取第一個就好。
#     根據 mode 決定呼叫上面那些函數
#       
#
################################################################################

# 簡單設定一些參數
. ./network.config
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=compose-nelong-network.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=compose-ca.yaml
COMPOSE_FILE_COUCH=compose-couch.yaml

# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

# BFT activated flag
# BFT=0
# 簡單設定一些參數結束

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

if [ "$MODE" == "cc" ] ; then
  if [ "$CC_NAME" == "" ]; then
    errorln "Chaincode name not provided. Use -ccn <chaincode_name> to specify the chaincode name."
    printHelp $MODE
    exit 1
  fi
  CONFIG_FILE=".cc_config_${CC_NAME}.env"
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    CHANNEL_NAME="mychannel"
    CC_VERSION="1.0"
    CC_SEQUENCE="1"
    CC_INIT_FCN=""
    CC_END_POLICY=""
    CC_COLL_CONFIG=""
    DELAY="3"
    MAX_RETRY="5"
    VERBOSE="false"
  fi
fi

# parse subcommands if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  # check for the createChannel subcommand
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  # check for the cc command
  elif [[ "$MODE" == "cc" ]]; then
    if [ "$1" != "-h" ]; then
      export SUBCOMMAND=$key
      shift
    fi
  fi
fi

# test_function here
function test_function() {
  . scripts/envVar.sh 3
  . scripts/ccutils.sh
  setGlobals 1
  peer chaincode invoke -o localhost:6050 --ordererTLSHostnameOverride orderer.nelong.com --tls --cafile "${PWD}/organizations/ordererOrganizations/nelong.com/orderers/orderer.nelong.com/msp/tlscacerts/tlsca.nelong.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.nelong.com/peers/peer0.org1.nelong.com/tls/ca.crt" --peerAddresses localhost:8051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.nelong.com/peers/peer0.org2.nelong.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org3.nelong.com/peers/peer0.org3.nelong.com/tls/ca.crt" -c '{"function":"CreateAsset","Args":["asset8","blue","16","Kelley","750"]}'
}

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $MODE
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -nan )
    if [[ "$MODE" != "up" && "$MODE" != "restart" ]]; then
      errorln "The -nan flag is only valid when using the up command"
      printHelp $MODE
      exit 1
    fi
    ORGS_NUM="$2"
    echo "ORGS_NUM=$ORGS_NUM" > "$ENV_FILE"
    shift

    orgs_names=()
    for ((j=1; j<=ORGS_NUM; j++)); do
      orgs_names+=("${2}")
      shift
    done
    ;;
  # -bft )
  #   BFT=1
  #   ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY=$2
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION=$2
    shift
    ;;
  -ccs )
    CC_SEQUENCE=$2
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY=$2
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG=$2
    shift
    ;;
  -cci )
    CC_INIT_FCN=$2
    shift
    ;;
  -ccaasdocker )
    CCAAS_DOCKER_RUN="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  -org )
    ORG="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -ccic )
    CC_INVOKE_CONSTRUCTOR="$2"
    shift
    ;;
  -ccqc )
    CC_QUERY_CONSTRUCTOR="$2"
    shift
    ;;    
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# 要不要使用 BFT
# if [ $BFT -eq 1 ]; then
#   export FABRIC_CFG_PATH=${PWD}/bft-config
#   COMPOSE_FILE_BASE=compose-nelong-network.yaml
# fi

# 判斷是否已有憑證（crypto material）
if [ ! -d "organizations/peerOrganizations" ]; then
  CRYPTO_MODE="with crypto from Certificate Authorities"
else
  CRYPTO_MODE=""
fi

# 根據 MODE 決定執行什麼動作
if [ "$MODE" == "up" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries. It would create ${ORGS_NUM} orgs"
  networkUp
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'."
  # infoln "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds"
  createChannel # $BFT
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
  networkDown
  rm -f .network.env
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
  networkDown
  infoln "Uping network right now yo"
  networkUp
elif [ "$MODE" == "deployCC" ]; then
  infoln "deploying chaincode on channel '${CHANNEL_NAME}'"
  deployCC
# elif [ "$MODE" == "deployCCAAS" ]; then
#   infoln "deploying chaincode-as-a-service on channel '${CHANNEL_NAME}'"
#   deployCCAAS
elif [ "$MODE" == "cc" ]; then
  if [ "$SUBCOMMAND" == "package" ]; then
    packageChaincode
  elif [ "$SUBCOMMAND" == "list" ]; then
    listChaincode
  elif [ "$SUBCOMMAND" == "invoke" ]; then
    invokeChaincode
  elif [ "$SUBCOMMAND" == "query" ]; then
    queryChaincode
  elif [ "$SUBCOMMAND" == "install" ]; then
    installChaincodeForOrg
  elif [ "$SUBCOMMAND" == "queryInstalled" ]; then
    queryInstalledForOrg
  elif [ "$SUBCOMMAND" == "approve" ]; then
    approveForOrg
  elif [ "$SUBCOMMAND" == "commit" ]; then
    CommitChaincodeDefinitionForOrg
  elif [ "$SUBCOMMAND" == "queryCommitted" ]; then
    queryCommittedForOrg
  fi
  cat > "$CONFIG_FILE" <<EOF
CHANNEL_NAME=${CHANNEL_NAME}
CC_SRC_PATH=${CC_SRC_PATH}
CC_VERSION=${CC_VERSION}
CC_SEQUENCE=${CC_SEQUENCE}
CC_INIT_FCN=${CC_INIT_FCN}
CC_END_POLICY=${CC_END_POLICY}
CC_COLL_CONFIG=${CC_COLL_CONFIG}
DELAY=${DELAY}
MAX_RETRY=${MAX_RETRY}
VERBOSE=${VERBOSE}
CC_SEQUENCE=${CC_SEQUENCE}
EOF
elif [ "$MODE" == "test" ]; then
  test_function
elif [ "$MODE" == "-v" ]; then
  infoln "Nelong-Network $VERSION"
else
  printHelp
  exit 1
fi