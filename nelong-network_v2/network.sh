#!/usr/bin/env bash
#
# Program Name: nelong-network
# Description: Hyperledger Fabric Network
# Author: nelong
# CreateDate: 2025/05/21
#
# Chage Log:
# 2.0 2025/05/20 : Create
# 2.0 2025/05/20 : A separately constructed network
#

VERSION="v2.0.0"
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
export VERBOSE=false


export IDENTITY
export DOMAIN_NAME
export ORDERER_HOST
export LISTEN_PORT
export ORDERER_LISTEN_PORT
export ORDERER_ADMIN_LISTEN_PORT
export CHAINCODE_PORT
export FABRIC_CA_SERVER_PORT
export OPERATIONS_LISTEN_PORT
export FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS
export CA_ID
export CA_PW
export REGISTER_ID
export REGISTER_PW
export REGISTER_USER_ID
export REGISTER_USER_PW
export REGISTER_ADMIN_ID
export REGISTER_ADMIN_PW
export NODE_PATH
export ORG_PATH
export USERS_PATH
export ADMIN_PATH
export COMPOSE_PATH
export CLI_COMPOSE_PATH
export CLI_COMPOSE_CA_PATH
export COMPOSE_FILE_CA
export ORG_NAME
export ORDERER_CA
export ORDERER_ADMIN_TLS_SIGN_CERT
export ORDERER_ADMIN_TLS_PRIVATE_KEY
export FABRIC_CFG_PATH
export BLOCKFILE_PATH
export CHAINCODE_PATH



# 切換到root目錄，並設置trap讓結束的時候回到原來的目錄
pushd ${ROOTDIR} > /dev/null
trap "popd > /dev/null" EXIT

# 輸出help資訊
. scripts/utils.sh



: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}


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
  if [ -d $NODE_PATH ]; then
    rm -Rf $NODE_PATH
  fi

  # 使用 Fabric CA 建立加密材料
  infoln "Generating certificates using Fabric CA"
  # 先根據組織數創建相對應的 .yaml 以配置 docker
  . compose/generate_ca_compose.sh
  ${CONTAINER_CLI_COMPOSE} -f ${COMPOSE_CA_PATH} -f ${CLI_COMPOSE_CA_PATH} up -d 2>&1

  . scripts/registerEnroll.sh

  # 一直睡以確保已建立 CA 文件
  while :
  do
    if [ ! -f "${ORG_PATH}/tls-cert.pem" ]; then
      sleep 1
    else
      break
    fi
  done

  # 在進行註冊和登記呼叫之前，一直睡以確保 CA 服務已初始化並可以接受請求
  #   - 設定 Fabric CA client 的工作目錄（會在這裡產生證書檔等）
  export FABRIC_CA_CLIENT_HOME="${NODE_PATH}/${DOMAIN_NAME}.com"
  COUNTER=0
  rc=1

  while [[ $rc -ne 0 && $COUNTER -lt $MAX_RETRY ]]; do
    sleep 1
    # set -x
    fabric-ca-client getcainfo -u https://${CA_ID}:${CA_PW}@localhost:${FABRIC_CA_SERVER_PORT} --caname ca-${ORG_NAME,,} --tls.certfiles "${ORG_PATH}/ca-cert.pem"
    res=$?
  # { set +x; } 2>/dev/null
  rc=$res  # Update rc
  COUNTER=$((COUNTER + 1))
  done
  if [ "$IDENTITY" = "orderer" ]; then
    infoln "Creating Orderer Org Identities"
    createOrderer
  else
    infoln "Creating Org Identities"
    createOrg
  fi
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
  # . ./configtx/generate-configtx.sh
  checkPrereqs

  # generate artifacts if they don't exist
  createOrgs

  . ./compose/generate-compose.sh
  . ./compose/docker/generate-docker.sh

  COMPOSE_FILES="-f ${COMPOSE_PATH} -f ${CLI_COMPOSE_PATH}"


  DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} up -d 2>&1

  $CONTAINER_CLI ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}


function createChannelcheck() {
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

  if [[ $len -ge 4 ]] && [[ ! -d "$NODE_PATH" ]]; then
    echo "Bringing network down to sync certs with containers"
    networkDown
  fi

  [[ $len -lt 4 ]] || [[ ! -d "$NODE_PATH" ]] && bringUpNetwork="true" || echo "Network Running Already"

  if [ $bringUpNetwork == "true"  ]; then
    infoln "Bringing up network"
    networkUp
  fi

  # 前面都在確定 network 起來而已，只有這一步真的在做事...
  . ./scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
}


## 呼叫 script 以打包鏈碼
function packagecc() {
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
  . scripts/envVar.sh
  . scripts/ccutils.sh

  setGlobals

  println
  queryInstalledOnPeer
  println

  listAllCommitted
}

## 呼叫 script 以 invoke 
function invokeChaincode() {
  . scripts/envVar.sh
  . scripts/ccutils.sh

  setGlobals

  chaincodeInvoke $CHANNEL_NAME $CC_NAME $CC_INVOKE_CONSTRUCTOR

}

## 呼叫 script 以 query chaincode 
function queryChaincode() {
  . scripts/envVar.sh
  . scripts/ccutils.sh
  setGlobals

  chaincodeQuery $CHANNEL_NAME $CC_NAME $CC_QUERY_CONSTRUCTOR

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
  COMPOSE_BASE_FILES="-f ${COMPOSE_PATH} -f ${CLI_COMPOSE_PATH}"
  COMPOSE_CA_FILES="-f ${COMPOSE_CA_PATH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_CA}"
  COMPOSE_FILES="${COMPOSE_BASE_FILES} ${COMPOSE_CA_FILES}"


  if [ "${CONTAINER_CLI}" == "docker" ]; then
    DOCKER_SOCK=$DOCKER_SOCK ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} down --volumes --remove-orphans
  else
    fatalln "Container CLI  ${CONTAINER_CLI} not supported"
  fi

  # COMPOSE_FILE_BASE=$temp_compose
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # 移除 volume
    ${CONTAINER_CLI} volume rm docker_peer0.${ORG_NAME,,}.${DOMAIN_NAME}.com docker_orderer.${ORG_NAME,,}.${DOMAIN_NAME}.com
    clearContainers
    removeUnwantedImages
    # 移除 genesis block、組織資料、CA 資料庫
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c "cd /data && rm -rf system-genesis-block/*.block $NODE_PATH channel-artifacts log.txt *.tar.gz"
  fi

  sudo rm -rf $NODE_PATH
  sudo rm -rf $ORG_PATH
  sudo rm -rf $CLI_COMPOSE_PATH
  sudo rm -rf $COMPOSE_CA_PATH
  sudo rm -rf $COMPOSE_PATH
  sudo rm -rf $CONFIG_FILE
  sudo rm -rf $SETTING_CONFIG_FILE
  sudo rm -rf $PATH_CONFIG_FILE
  rm -rf $CHAINCODE_PATH
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

function installcc() {
  infoln "Installing chaincode on channel '${CHANNEL_NAME}'"
  . ./scripts/envVar.sh
  . ./scripts/ccutils.sh
  setGlobals
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_PATH}/${CC_NAME}_${CC_VERSION}.tar.gz)
  installChaincode
}

function queryInstalledcc() {
  infoln "Querying installed chaincode on channel '${CHANNEL_NAME}'"
  . ./scripts/envVar.sh
  . ./scripts/ccutils.sh
  setGlobals
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_PATH}/${CC_NAME}_${CC_VERSION}.tar.gz)
  resolveSequence
  queryInstalled
}

function approvecc() {
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
  . ./scripts/envVar.sh
  . ./scripts/ccutils.sh

  setGlobals
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_PATH}/${CC_NAME}_${CC_VERSION}.tar.gz)
  approveForMyOrg
}

function CommitChaincodeDefinitioncc() {
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
  . ./scripts/envVar.sh
  . ./scripts/ccutils.sh

  setGlobals
  commitChaincodeDefinition "${org_args[@]}"
}


function queryCommittedcc() {
  if [ "$CHANNEL_NAME" == "" ]; then
    errorln "Channel name not provided. Use -c <channel_name> to specify the channel."
    printHelp $MODE
    exit 1
  fi

  infoln "Committing chaincode on channel '${CHANNEL_NAME}'"
  . ./scripts/envVar.sh
  . ./scripts/ccutils.sh
  DELAY=$CLI_DELAY
  setGlobals
  queryCommitted
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
COMPOSE_FILE_BASE=compose.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=compose-ca.yaml

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

ORG_NAME=$1
shift

SETTING_CONFIG_FILE=".${ORG_NAME}.setting_config.env"
if [ -f "$SETTING_CONFIG_FILE" ]; then
  eval $(sudo cat "$SETTING_CONFIG_FILE")
else
  IDENTITY="peer"
  DOMAIN_NAME="nl"
  ORDERER_HOST="orderer.nl.com"
  LISTEN_PORT="7051"
  ORDERER_LISTEN_PORT="6051"
  ORDERER_ADMIN_LISTEN_PORT="6052"
  CHAINCODE_PORT="7052"
  FABRIC_CA_SERVER_PORT="7054"
  OPERATIONS_LISTEN_PORT="9444"
  FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS="17054"
  CA_ID="ca-${ORG_NAME,,}"
  CA_PW="ca-${ORG_NAME,,}pw"
  REGISTER_ID="${ORG_NAME,,}"
  REGISTER_PW="${ORG_NAME,,}pw"
  USER_NUMBER=1
  REGISTER_USER_ID=("${ORG_NAME,,}user1")
  REGISTER_USER_PW=("${ORG_NAME,,}user1pw")
  REGISTER_ADMIN_ID="${ORG_NAME,,}admin"
  REGISTER_ADMIN_PW="${ORG_NAME,,}adminpw"
fi

PATH_CONFIG_FILE=".${ORG_NAME}.path_config.env"
if [ -f "$PATH_CONFIG_FILE" ]; then
  eval $(sudo cat "$PATH_CONFIG_FILE")
else
  NODE_PATH="${PWD}/peer"
  ORG_PATH="${PWD}/org"
  USERS_PATH=("${NODE_PATH}/users/User1@${DOMAIN_NAME}.com")
  ADMIN_PATH="${NODE_PATH}/users/Admin@${DOMAIN_NAME}.com"
  CLI_COMPOSE_PATH="${PWD}/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"
  CLI_COMPOSE_CA_PATH="${PWD}/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_CA}"
  COMPOSE_PATH="${PWD}/compose/${COMPOSE_FILE_BASE}"
  COMPOSE_CA_PATH="${PWD}/compose/${COMPOSE_FILE_CA}"
  BLOCKFILE_PATH="./channel-artifacts"
  CHAINCODE_PATH="${PWD}/chaincode"
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
  if [[ "$MODE" == "cc" || "$MODE" == "createChannel" ]]; then
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
  peer chaincode invoke -o localhost:6050 --ordererTLSHostnameOverride orderer.nelong.com --tls --cafile "${PWD}/organizations/ordererOrganizations/nelong.com/orderers/orderer.nelong.com/msp/tlscacerts/tlsca.nelong.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "$NODE_PATH/org1.nelong.com/peers/peer0.org1.nelong.com/tls/ca.crt" --peerAddresses localhost:8051 --tlsRootCertFiles "$NODE_PATH/org2.nelong.com/peers/peer0.org2.nelong.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "$NODE_PATH/org3.nelong.com/peers/peer0.org3.nelong.com/tls/ca.crt" -c '{"function":"CreateAsset","Args":["asset8","blue","16","Kelley","750"]}'
}

# parse flags

function for_up_only() {
  if [[ "$MODE" != "up" && "$MODE" != "restart" ]]; then
    errorln "The $2 flag is only valid when using the up command"
    printHelp $MODE
    exit 1
  fi
}

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
  -id )
    for_up_only
    IDENTITY="$2"
    shift
    ;;
  -dn )
    for_up_only
    DOMAIN_NAME="$2"
    shift
    ;;
  -oh )
    ORDERER_HOST="$2"
    shift
    ;;
  -ohlp )
    ORDERER_ADMIN_LISTEN_PORT="$2"
    shift
    ;;
  -lp )
    for_up_only
    LISTEN_PORT="$2"
    shift
    ;;
  -odlp )
    ORDERER_LISTEN_PORT="$2"
    shift
    ;;
  -cp )
    for_up_only
    CHAINCODE_PORT="$2"
    shift
    ;;
  -fcp )
    for_up_only
    FABRIC_CA_SERVER_PORT="$2"
    shift
    ;;
  -olp )
    for_up_only
    OPERATIONS_LISTEN_PORT="$2"
    shift
    ;;
  -fca )
    for_up_only
    FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS="$2"
    shift
    ;;
  -ri )
    for_up_only
    REGISTER_ID="$2"
    shift
    ;;
  -rp )
    for_up_only
    REGISTER_PW="$2"
    shift
    ;;
  -un )
    for_up_only
    USER_NUMBER="$2"
    shift
    ;;
  -cid )
    for_up_only
    if [[ -z "$2" || "$2" == -* ]]; then
      errorln "Wrong number of CA ID provided. Use -cid <ca_id> to specify the CA ID."
      printHelp $MODE
      exit 1
    fi
    CA_ID="$2"
    shift
    ;;
  -cpw )
    for_up_only
    if [[ -z "$2" || "$2" == -* ]]; then
      errorln "Wrong number of CA password provided. Use -cpw <ca_password> to specify the CA password."
      printHelp $MODE
      exit 1
    fi
    CA_PW="$2"
    shift
    ;;
  -uid )
    for_up_only
    REGISTER_USER_ID=()
    for ((j=1; j<=USER_NUMBER; j++)); do
      if [[ -z "$2" || "$2" == -* ]]; then
        errorln "Wrong number of user ID provided. Use -uid <user_id> to specify the user ID."
        printHelp $MODE
        exit 1
      fi
      REGISTER_USER_ID+=("${2}")
      shift
    done
    ;;
  -upw )
    for_up_only
    REGISTER_USER_PW=()
    for ((j=1; j<=USER_NUMBER; j++)); do
      if [[ -z "$2" || "$2" == -* ]]; then
        errorln "Wrong number of user password provided. Use -upw <user_password> to specify the user password."
        printHelp $MODE
        exit 1
      fi
      REGISTER_USER_PW+=("${2}")
      shift
    done
    ;;
  -aid )
    for_up_only
    ADMIN_ID="$2"
    shift
    ;;
  -apw )
    for_up_only
    ADMIN_PW="$2"
    shift
    ;;
  -np )
    for_up_only
    if [[ "$2" = /* ]]; then
      NODE_PATH="$2"
    else
      NODE_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -op )
    for_up_only
    if [[ "$2" = /* ]]; then
      ORG_PATH="$2"
    else
      ORG_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -up )
    for_up_only
    USERS_PATH=()
    for ((j=1; j<=USER_NUMBER; j++)); do
      if [[ -z "$2" || "$2" == -* ]]; then
        errorln "Wrong number of user path provided. Use -up <user_path> to specify the user path."
        printHelp $MODE
        exit 1
      fi
      if [[ "$2" = /* ]]; then
        USERS_PATH+=("${2}")
      else
        USERS_PATH+=("${PWD}/$2")
      fi
      shift
    done
    ;;
  -ap )
    for_up_only
    if [[ "$2" = /* ]]; then
      ADMIN_PATH="$2"
    else
      ADMIN_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -ccpp )
    for_up_only
    if [[ "$2" = /* ]]; then
      CLI_COMPOSE_PATH="$2"
    else
      CLI_COMPOSE_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -ccpcap )
    for_up_only
    if [[ "$2" = /* ]]; then
      CLI_COMPOSE_CA_PATH="$2"
    else
      CLI_COMPOSE_CA_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -cpp )
    for_up_only
    if [[ "$2" = /* ]]; then
      COMPOSE_PATH="$2"
    else
      COMPOSE_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -cpcap )
    for_up_only
    if [[ "$2" = /* ]]; then
      COMPOSE_CA_PATH="$2"
    else
      COMPOSE_CA_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -ocap )
    if [[ "$2" = /* ]]; then
      ORDERER_CA="$2"
    else
      ORDERER_CA="${PWD}/$2"
    fi
    shift
    ;;
  -oatsp )
    if [[ "$2" = /* ]]; then
      ORDERER_ADMIN_TLS_SIGN_CERT="$2"
    else
      ORDERER_ADMIN_TLS_SIGN_CERT="${PWD}/$2"
    fi
    shift
    ;;
  -oatkp )
    if [[ "$2" = /* ]]; then
      ORDERER_ADMIN_TLS_PRIVATE_KEY="$2"
    else
      ORDERER_ADMIN_TLS_PRIVATE_KEY="${PWD}/$2"
    fi
    shift
    ;;
  -cgp )
    if [[ "$2" = /* ]]; then
      FABRIC_CFG_PATH="$2"
    else
      FABRIC_CFG_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -b )
    if [[ "$2" = /* ]]; then
      BLOCKFILE_PATH="$2"
    else
      BLOCKFILE_PATH="${PWD}/$2"
    fi
    shift
    ;;
  -chcp )
    if [[ "$2" = /* ]]; then
      CHAINCODE_PATH="$2"
    else
      CHAINCODE_PATH="${PWD}/$2"
    fi
    if [ ! -d "$CHAINCODE_PATH" ]; then
      mkdir -p "$CHAINCODE_PATH"
    fi
    shift
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY=$2
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
    CC_END_POLICY==$2
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
  -commit )
    org_args=()
    while [[ $# -ge 5 && "$2" != -* ]] ; do
      org_args+=("$2")
      TEMP_PATH=""
      if [[ "$3" = /* ]]; then
        TEMP_PATH="$3"
      else
        TEMP_PATH="${PWD}/$3"
      fi
      org_args+=("${TEMP_PATH}")
      if [[ "$4" = /* ]]; then
        TEMP_PATH="$4"
      else
        TEMP_PATH="${PWD}/$4"
      fi
      org_args+=("${TEMP_PATH}")
      org_args+=("$5")
      shift 4
    done
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

# 判斷是否已有憑證（crypto material）
if [ ! -d "$NODE_PATH" ]; then
  CRYPTO_MODE="with crypto from Certificate Authorities"
else
  CRYPTO_MODE=""
fi

# 根據 MODE 決定執行什麼動作
if [ "$MODE" == "up" ]; then
  infoln "Starting up network with nodes in CLI timeout of '${MAX_RETRY}' tries."
  networkUp
elif [ "$MODE" == "createChannel" ]; then
  createChannelcheck
  if [ "$SUBCOMMAND" == "createGenesisBlock" ]; then
    infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
    createChannelGenesisBlock
  elif [ "$SUBCOMMAND" == "createChannel" ]; then
    infoln "Creating channel '${CHANNEL_NAME}'"
    warnln "You must have -ocap, -oatsp, -oatkp, which means orderer TLS CA path, orderer admin TLS sign cert, orderer admin TLS private key, to create channel."
    createChannel
    successln "Channel '$CHANNEL_NAME' created"
  elif [ "$SUBCOMMAND" == "joinChannel" ]; then
    infoln "Joining channel '${CHANNEL_NAME}'"
    joinChannel
  elif [ "$SUBCOMMAND" == "updateAnchorPeers" ]; then
    infoln "Updating anchor peer for channel '${CHANNEL_NAME}'"
    setAnchorPeer
  else
    errorln "Unknown subcommand: ${SUBCOMMAND}"
    printHelp $MODE
    exit 1
  fi
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
  networkDown
  exit 1
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
  networkDown
  infoln "Uping network right now yo"
  networkUp
# elif [ "$MODE" == "deployCCAAS" ]; then
#   infoln "deploying chaincode-as-a-service on channel '${CHANNEL_NAME}'"
#   deployCCAAS
elif [ "$MODE" == "cc" ]; then
  if [ "$SUBCOMMAND" == "package" ]; then
    packagecc
  elif [ "$SUBCOMMAND" == "list" ]; then
    listChaincode
  elif [ "$SUBCOMMAND" == "invoke" ]; then
    invokeChaincode
  elif [ "$SUBCOMMAND" == "query" ]; then
    queryChaincode
  elif [ "$SUBCOMMAND" == "install" ]; then
    installcc
  elif [ "$SUBCOMMAND" == "queryInstalled" ]; then
    queryInstalledcc
  elif [ "$SUBCOMMAND" == "approve" ]; then
    approvecc
  elif [ "$SUBCOMMAND" == "commit" ]; then
    CommitChaincodeDefinitioncc
  elif [ "$SUBCOMMAND" == "queryCommitted" ]; then
    queryCommittedcc
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

sudo tee "$PATH_CONFIG_FILE" > /dev/null <<EOF
NODE_PATH=${NODE_PATH}
ORG_PATH=${ORG_PATH}
USERS_PATH=${USERS_PATH[@]}
ADMIN_PATH=${ADMIN_PATH}
CLI_COMPOSE_PATH=${CLI_COMPOSE_PATH}
CLI_COMPOSE_CA_PATH=${CLI_COMPOSE_CA_PATH}
COMPOSE_PATH=${COMPOSE_PATH}
COMPOSE_CA_PATH=${COMPOSE_CA_PATH}
ORDERER_CA=${ORDERER_CA}
ORDERER_ADMIN_TLS_SIGN_CERT=${ORDERER_ADMIN_TLS_SIGN_CERT}
ORDERER_ADMIN_TLS_PRIVATE_KEY=${ORDERER_ADMIN_TLS_PRIVATE_KEY}
FABRIC_CFG_PATH=${FABRIC_CFG_PATH}
BLOCKFILE_PATH=${BLOCKFILE_PATH}
CHAINCODE_PATH=${CHAINCODE_PATH}
EOF

sudo tee "$SETTING_CONFIG_FILE" > /dev/null <<EOF
IDENTITY=${IDENTITY}
DOMAIN_NAME=${DOMAIN_NAME}
ORDERER_HOST=${ORDERER_HOST}
LISTEN_PORT=${LISTEN_PORT}
ORDERER_LISTEN_PORT=${ORDERER_LISTEN_PORT}
ORDERER_ADMIN_LISTEN_PORT=${ORDERER_ADMIN_LISTEN_PORT}
CHAINCODE_PORT=${CHAINCODE_PORT}
FABRIC_CA_SERVER_PORT=${FABRIC_CA_SERVER_PORT}
OPERATIONS_LISTEN_PORT=${OPERATIONS_LISTEN_PORT}
FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=${FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS}
CA_ID=${CA_ID}
CA_PW=${CA_PW}
REGISTER_ID=${REGISTER_ID}
REGISTER_PW=${REGISTER_PW}
REGISTER_USER_ID=${REGISTER_USER_ID[@]}
REGISTER_USER_PW=${REGISTER_USER_PW}
REGISTER_ADMIN_ID=${REGISTER_ADMIN_ID[@]}
REGISTER_ADMIN_PW=${REGISTER_ADMIN_PW}
EOF

sudo chown root:root $PATH_CONFIG_FILE
sudo chown root:root $SETTING_CONFIG_FILE
sudo chmod 600 $PATH_CONFIG_FILE
sudo chmod 600 $SETTING_CONFIG_FILE