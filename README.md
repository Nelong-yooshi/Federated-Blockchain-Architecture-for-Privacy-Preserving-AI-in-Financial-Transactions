# Federated-Blockchain-Architecture-for-Privacy-Preserving-AI-in-Financial-Transactions
Introduction to AI, Spring 2025 NYCU (Team 17)

## Problem Statement

In the banking industry, detecting fraudulent or anomalous customer behavior is a critical task. However, financial institutions often work in isolation, each with its own dataset and detection model. This siloed approach limits the effectiveness of anomaly detection, especially when suspicious behavior spans across multiple banks.

While sharing data among banks could improve detection accuracy, it introduces significant **privacy risks** and **regulatory challenges**. Directly exchanging customer data violates data protection laws (e.g., GDPR, local banking regulations) and raises concerns over security, trust, and accountability.

The core challenges are:

- **Data Privacy**: How can banks collaborate without exposing sensitive customer information?
- **Model Sharing**: Can machine learning models be trained jointly across banks without data leakage?
- **Transparency and Auditability**: How can model updates and anomaly reports be made verifiable to build inter-bank trust?
- **Regulatory Compliance**: How to ensure the collaboration respects legal boundaries and audit requirements?

## Overall System Design
To slove the problem, we except to explore an AI learning mode combing with data on-chain. And another two ways would be implemented and compared in this repository to analyze trade-offs between **performance**, **privacy**, **scalability**, and **regulatory readiness** in financial AI systems.
### 1. Centralized Training with Manual Reporting

Each bank independently trains its own anomaly detection model using local customer transaction data. Anomalous users are manually reported to a central authority or shared with other institutions on request.

- **Pros**:
  - Simple to implement
  - No synchronization required
- **Cons**:
  - No collaboration in training
  - Delayed or inconsistent anomaly reporting
  - Limited detection capability due to isolated data
  - Unable to verify source and authenticity

### 2. Federated Learning (FL)

Multiple banks collaboratively train a global model by sharing model weights instead of raw data. A central aggregator (e.g., regulatory body or consortium) coordinates the learning rounds.

- **Pros**:
  - Preserves data privacy (no raw data exchange)
  - Improved model accuracy through collaborative learning
  - Scalable across institutions
- **Cons**:
  - **Vulnerable to adversarial participants** (e.g., model poisoning or data poisoning from malicious banks)
  - **Privacy leakage from model updates**: Personal data can still be inferred through gradient inversion or parameter attacks
  - **Model management is complex**: Difficult to enforce consistent model versions or rollback faulty updates
  - Requires reliable and secure communication infrastructure
  - Trust is still needed in the aggregator (required a trusted third party training model)

### 3. On-Chain Learning

Federated learning is enhanced with blockchain and zero-knowledge proofs (ZKP). Model updates and anomaly events are committed to a permissioned blockchain (e.g., Hyperledger Fabric), allowing transparent verification without revealing sensitive data.

- **Pros**:
  - **Transparent collaboration**: All training activity, model updates, and anomalies are traceable and auditable on-chain
  - **Immutability & verifiability**: Historical records cannot be tampered with, ensuring integrity and accountability
  - **TEE isolation**: Model training occurs inside a trusted execution environment where **no party—including the hosting bank—can inspect the raw data**
  - **Full-data training with dynamic models**: Smart contracts define the model architecture, allowing training to use **all datasets simultaneously** and **adapt the model structure** (e.g., switch from logistic regression to a neural network) as long as policies are met
  - **Regulatory compliance by design**: ZKPs ensure that training followed the rules without revealing sensitive data

- **Cons**:
  - High system complexity and development overhead
  - Performance overhead due to cryptographic proofs and blockchain latency
  - Requires integration of blockchain, model frameworks, and TEE infrastructure (e.g., Intel SGX, AMD SEV)


## Current Approach
hi

## Federated Learning
hi

## Blockchain-based AI learning
### Nelong-Network framework
The network is based on the framework of [[1]Fabric Hyperledger samples][ref1]. 

See more about fabric hyperledger at [[2]Hyperledger Docs][ref2]

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
./network.sh deployCC -c <channel_name> -ccn basic -ccp <the_path_of_your_contract>
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

### Smart Contract
hi

## Outcome Evaluates
hi

## reference
* <a id="ref1">[1]</a> Fabric Hyperledger samples: https://github.com/hyperledger/fabric-samples
* <a id="ref2">[2]</a> Hyperledger Fabric Documentation: https://hyperledger-fabric.readthedocs.io/en/latest/index.html  

[ref1]: #ref1
[ref2]: #ref2
