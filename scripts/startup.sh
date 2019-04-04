#!/bin/bash
set -e

export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
CC_SRC_LANGUAGE=${1:-"go"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`
if [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
  CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
  CC_SRC_PATH=CC_SRC_PATH=/opt/gopath/src/github.com/asset-registery
  echo Compiling TypeScript code into JavaScript ...
  pushd ./../chaincode/asset-registery
  npm install
  npm run build
  popd
  echo Finished compiling TypeScript code into JavaScript
else
  echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
  echo Supported chaincode languages are: go, javascript, and typescript
  exit 1
fi

rm -rf ./hfc-key-store

cd ./../basic-network
./start.sh

docker-compose -f ./docker-compose.yml up -d cli
# this command to install chaincode
docker  exec  -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" -e  "CORE_PEER_LOCALMSPID=Org1MSP"  cli  peer  chaincode  install -v 1.0 -n asset -p "/opt/gopath/src/github.com/asset-registery" -l "node"
docker exec -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" -e "CORE_PEER_LOCALMSPID=Org1MSP"  cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n asset -l "node" -v 1.0 -c '{"Args":[]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
sleep 10
docker exec -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" -e "CORE_PEER_LOCALMSPID=Org1MSP"  cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n asset -c '{"function":"initLedger","Args":[]}'