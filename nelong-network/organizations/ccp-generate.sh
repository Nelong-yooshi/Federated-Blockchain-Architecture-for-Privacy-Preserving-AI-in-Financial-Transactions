#!/usr/bin/env bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORGS_NUM=$1
BASE_PORT=7051
BASE_CAPORT=7054
for (( j=1; j<=ORGS_NUM; j++ ))
do
  ORG=$j
  PORT=$((BASE_PORT + (j - 1) * 1000))
  OP_PORT=$((BASE_CAPORT + (j - 1) * 1000))

  PEERPEM=organizations/peerOrganizations/org${ORG}.nelong.com/tlsca/tlsca.org${ORG}.nelong.com-cert.pem
  CAPEM=organizations/peerOrganizations/org${ORG}.nelong.com/ca/ca.org${ORG}.nelong.com-cert.pem

  echo "$(json_ccp $ORG $PORT $OP_PORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org${ORG}.nelong.com/connection-org${ORG}.json
  echo "$(yaml_ccp $ORG $PORT $OP_PORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org${ORG}.nelong.com/connection-org${ORG}.yaml
done