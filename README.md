# Federated-Blockchain-Architecture-for-Privacy-Preserving-AI-in-Financial-Transactions
Introduction to AI, Spring 2025 NYCU (Team 17)

## Current Approach
hi

## Federated Learning
hi

## Blockchain-based AI learning
### Nelong-Network framework
The network is based on the framework of [Fabric Hyperledger samples][ref2]. And see more about fabric hyperledger at [Hyperledger Docs][ref1]

### Before start
First, clone the `nelong-network` folder and enter it. Then, you might want to use `chmod -R +x ./` to manage execution permissions.  
There are several common commands designed in this network. For more parameter settings, you can view the help info using `./network.sh <any_mode> -h`.

### Start and Terminate the Network
* **Start network**: `./network.sh up`
* **Terminate network**: `./network.sh down`
* **Reopen network**: `./network.sh restart`

In fact, the number of organizations in this project is based on a **hardcoded numbering** system, inherited from the original test-network.  
You can start by setting the `-nan` (number and name) parameter, like:  
  `./network.sh up -nan 3 Nihow Hi GoodMorning` or `./network.sh restart -nan 3 Nihow Hi GoodMorning`.

See more details with `./network.sh up -h`, `./network.sh down -h`, or `./network.sh restart -h`.

> When testing, I recommend using `./network.sh restart`, which simply combines `down` and `up` in one command.

### Create channel
After starting your network, you can create your first channel by using:
  `./network.sh createChannel -c <channelName>`  
See more details with `./network.sh createChannel -h`.

### Deploy your smart contract
In this project, we develop the smart contracts using the Go language. Therefore, the network currently only supports Go chaincode.  
There are two deployment methods:  
1. An automatic deployment process (for testing).  
2. A manual deployment process (recommended for production).

The automatic method is useful for testing. Although real-world deployments should avoid centralized container management, this method is efficient for testing purposes:

```bash=
./network.sh deployCC -ccn basic -ccp <the_path_of_your_contract>
```
The manual deployment process includes the following steps:
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
You may use only part of these commands if you want the process to stop at a specific step.
See more details with `./network.sh deployCC -h` and `./network.sh cc -h`.

## Smart Contract
hi

## reference
<a id="ref1">[1]</a> Hyperledger Fabric Documentation: https://hyperledger-fabric.readthedocs.io/en/latest/index.html  
<a id="ref2">[2]</a> Fabric Hyperledger samples: https://github.com/hyperledger/fabric-samples

[ref1]: #ref1
[ref2]: #ref2
