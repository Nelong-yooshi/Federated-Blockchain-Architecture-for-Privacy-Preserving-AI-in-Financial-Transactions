generateAll1() {
  local i
  for (( i=1; i<=ORGS_NUM; i++ ))
  do
    echo "  - &Org${i}
      Name: Org${i}MSP
      ID: Org${i}MSP
      MSPDir: ../organizations/peerOrganizations/org${i}.nelong.com/msp
  
      Policies:
        Readers:
          Type: Signature
          Rule: \"OR('Org${i}MSP.admin', 'Org${i}MSP.peer', 'Org${i}MSP.client')\"
        Writers:
          Type: Signature
          Rule: \"OR('Org${i}MSP.admin', 'Org${i}MSP.client')\"
        Admins:
          Type: Signature
          Rule: \"OR('Org${i}MSP.admin')\"
        Endorsement:
          Type: Signature
          Rule: \"OR('Org${i}MSP.peer')\"
  " >> configtx/configtx.yaml
  done
}

geneateALL2() {
  local i
  for (( i=1; i<=ORGS_NUM; i++ ))
  do
    echo "        - *Org${i}" >> configtx/configtx.yaml
  done
}


echo "Organizations:
  - &OrdererOrg
    Name: OrdererOrg
    ID: OrdererMSP
    MSPDir: ../organizations/ordererOrganizations/nelong.com/msp

    Policies:
      Readers:
        Type: Signature
        Rule: \"OR('OrdererMSP.member')\"
      Writers:
        Type: Signature
        Rule: \"OR('OrdererMSP.member')\"
      Admins:
        Type: Signature
        Rule: \"OR('OrdererMSP.admin')\"
    OrdererEndpoints:
      - orderer.nelong.com:6050" > configtx/configtx.yaml

generateAll1
echo "Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_5: true


Application: &ApplicationDefaults
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
    LifecycleEndorsement:
      Type: ImplicitMeta
      Rule: \"MAJORITY Endorsement\"
    Endorsement:
      Type: ImplicitMeta
      Rule: \"MAJORITY Endorsement\"
  Capabilities:
    <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
  Addresses:
    - orderer.nelong.com:6050
  BatchTimeout: 2s
  BatchSize:
    MaxMessageCount: 10
    AbsoluteMaxBytes: 99 MB
    PreferredMaxBytes: 512 KB
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
    BlockValidation:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"

Channel: &ChannelDefaults
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
  Capabilities:
    <<: *ChannelCapabilities

Profiles:
  ChannelUsingRaft:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      OrdererType: etcdraft
      EtcdRaft:
        Consenters:
          - Host: orderer.nelong.com
            Port: 6050
            ClientTLSCert: ../organizations/ordererOrganizations/nelong.com/orderers/orderer.nelong.com/tls/server.crt
            ServerTLSCert: ../organizations/ordererOrganizations/nelong.com/orderers/orderer.nelong.com/tls/server.crt
      Organizations:
        - *OrdererOrg
      Capabilities: *OrdererCapabilities
    Application:
      <<: *ApplicationDefaults
      Organizations:" >> configtx/configtx.yaml

geneateALL2