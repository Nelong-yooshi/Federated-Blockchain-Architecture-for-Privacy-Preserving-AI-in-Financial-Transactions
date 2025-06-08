#!/usr/bin/env bash

ORGS_NUM=$1
BASE_COUCHDB_PORT=5984

echo "version: '3.7'
networks:
  nelong:
    name: fabric_nelong
    
services:" > compose/compose-couch.yaml

for (( j=1; j<=ORGS_NUM; j++ ))
do
  COUCHDB_PORT=$((BASE_COUCHDB_PORT + (j - 1) * 1000))

  echo "  couchdb${j}:
    container_name: couchdb${j}
    image: couchdb:3.4.2
    labels:
      service: hyperledger-fabric
    # Populate the COUCHDB_USER and COUCHDB_PASSWORD to set an admin user and password
    # for CouchDB.  This will prevent CouchDB from operating in an \"Admin Party\" mode.
    environment:
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD=adminpw
    # Comment/Uncomment the port mapping if you want to hide/expose the CouchDB service,
    # for nelong map it to utilize Fauxton User Interface in dev environments.
    ports:
      - \"${COUCHDB_PORT}:5984\"
    networks:
      - nelong

  peer0.org${j}.nelong.com:
    environment:
      - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
      - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb${j}:5984
      # The CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME and CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD
      # provide the credentials for ledger to connect to CouchDB.  The username and password must
      # match the username and password set for the associated CouchDB.
      - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
      - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
    depends_on:
      - couchdb${j}
" >> compose/compose-couch.yaml
done