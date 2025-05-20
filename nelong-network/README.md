# Nelong Network

This file is descripting the script to build and using a Nelong Network. It can support following operations:

- Build the network with the specific number of organizations.
- Create the channel.
- Depoly the chaincode.
- Evoke the chaincode which has deploied on the channel.

## About the network

It's rewriting base on the [fabric-samples](https://github.com/hyperledger/fabric-samples).

## Before start
First, clone the `nelong-network` folder and enter it. Then, you might want to use `chmod -R +x ./` to manage execution permissions.  
There are several common commands designed in this network. For more parameter settings, you can view the help info using `./network.sh <any_mode> -h`.

You can use `./network.sh -v` to check if you install sucessful and check the version.

## Start and Terminate the Network `up` `down` `restart`
* **Start network**: `./network.sh up`

* **Terminate network**: `./network.sh down`

* **Reopen network**: `./network.sh restart`

In fact, the number of organizations in the original project is based on a **hardcoded numbering** system, inherited from the original test-network. We change it in our project, you can select the number by the flag `-nan`.

And there are the flags:
- `-nan`: <number of organizations and name of n orgs> - Number of organizations to create (default to 2) And name of the orgs (default to Org1, Org2)
- `-c`: <channel name> - Name of channel to create (defaults to mychannel)
- `-r`: <max retry> - CLI times out after certain number of attempts (defaults to 5)
- `-d`: <delay> - CLI delays for a certain number of seconds (defaults to 3)
- `-h`: Print this message

### Example:
```bash=
./network.sh up createChannel -c mychannel
```
```bash=
./network.sh up nan 4 NiHow OHiYoU Hi GoodMorning -c mychannel
```

> When testing, I recommend using `./network.sh restart`, which simply combines `down` and `up` in one command.

## Create channel `createChannel`
This operation would create a channel. And build up a network firstly, if you haven't build one.

And there are the flags:
- `-c`: <channel name> - Name of channel to create (defaults to mychannel)
- `-r`: <max retry> - CLI times out after certain number of attempts (defaults to 5)
- `-d`: <delay> - CLI delays for a certain number of seconds (defaults to 3)
- `-h`: Print this message

### Example:
```bash=
./network.sh createChannel -c newchannel
```

## Deploy your smart contract
In this project, we develop the smart contracts using the Go language. Therefore, the network currently only supports Go chaincode.  
There are two deployment methods:  
1. An automatic deployment process (for testing).  
2. A manual deployment process (recommended for production).

### The automatic method `deployCC`
The command would directly complete all of process to deploy the chaincode onto the channel. It is just useful for testing. Although real-world deployments should avoid centralized container management, this method is efficient for testing purposes.

#### Example
```bash=
./network.sh deployCC -c <channel_name> -ccn basic -ccp <the_path_of_your_contract>
```

### The manual deployment process `cc`
There are several mode to choice:
1. **list**: list chaincodes installed on a peer and committed on a channel
2. **package**: package a chaincode in tar format. Stores in directory packagedChaincode
3. **invoke**: execute an invoke operation
4. **query**: execute an query operation
5. **install**: install a chaincode on a peer
6. **queryinstalled**: query a chaincode definition installed on a peer
7. **commit**: commit a chaincode definition to a channel
8. **querycommitted**: query a chaincode definition committed to a channel

#### Example
It includes the following steps:
```bash=
# "basic" is <chaincode_name>
# "mychannel" is <channel_name>
# And there suppose that you build with three organizations.
./network.sh cc package -ccn basic -ccp <the_path_of_your_contract> -ccv 1.0
./network.sh cc install -ccn basic -org 1
./network.sh cc install -ccn basic -org 2
./network.sh cc install -ccn basic -org 3
./network.sh cc queryInstalled -c mychannel -ccn basic -org 1
./network.sh cc approve -c mychannel -ccn basic -org 1
./network.sh cc approve -c mychannel -ccn basic -org 2
./network.sh cc approve -c mychannel -ccn basic -org 3
./network.sh cc commit -c mychannel -ccn basic -org 1
./network.sh cc queryCommitted -c mychannel -ccn basic -org 1
./network.sh cc queryCommitted -c mychannel -ccn basic -org 2
./network.sh cc queryCommitted -c mychannel -ccn basic -org 3
```
You may use only part of these commands if you want the process to stop at a specific step. And there are the flags for both parts:
- `-c`: <channel name> - Name of channel to deploy chaincode to
- `-ccn`: <name> - Chaincode name
- `-ccv`: <version>  - Chaincode version. 1.0 (default), v2, version3.x, etc
- `-ccs`: <sequence>  - Chaincode definition sequence.  Must be auto (default) or an integer, 1 , 2, 3, etc
- `-ccp`: <path>  - File path to the chaincode
- `-ccep`: <policy>  - (Optional) Chaincode endorsement policy using signature policy syntax. The default policy requires an endorsement from all Orgs
- `-cccg`: <collection-config>  - (Optional) File path to private data collections configuration file
- `-cci`: <fcn name>  - (Optional) Name of chaincode initialization function. When a function is provided, the execution of init will be requested and the function will be invoked
- `-h`: Print this message

## Example
```bash=
./network.sh up createChannel -nan 3 Nihow Hi GoodMorning -c coolchannel
./network.sh deployCC -c coolchannel -ccn coolcc -ccp ./asset-transfer-basic/chaincode-go
```
```bash=
./network.sh restart -nan 3 Nihow Hi GoodMorning
./network.sh createChannel -c coolchannel
./network.sh cc package -ccn coolc -ccp ./asset-transfer-basic/chaincode-go -ccv 1.0
./network.sh cc install -ccn coolc -org 1
./network.sh cc install -ccn coolc -org 2
./network.sh cc install -ccn coolc -org 3
./network.sh cc queryInstalled -c coolchannel -ccn coolc -org 1
./network.sh cc approve -c coolchannel -ccn coolc -org 1
./network.sh cc approve -c coolchannel -ccn coolc -org 2
./network.sh cc approve -c coolchannel -ccn coolc -org 3
./network.sh cc commit -c coolchannel -ccn coolc -org 1
./network.sh cc queryCommitted -c coolchannel -ccn coolc -org 1
./network.sh cc queryCommitted -c coolchannel -ccn coolc -org 2
./network.sh cc queryCommitted -c coolchannel -ccn coolc -org 3
```
These two operations should achieve same outcome. You can use `./network.sh cc list -org 1` to check out whether you deploy sucessfully.