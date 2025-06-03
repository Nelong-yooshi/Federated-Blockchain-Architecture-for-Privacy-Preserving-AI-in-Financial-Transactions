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

## Implement
### Main Approach
**Secure Data Processing and Blockchain Interaction**:
1. Instruction Dispatch: The blockchain sends an instruction to the Oracle to initiate TEE execution.
2. Oracle-to-TEE Command: Oracle issues the command to the TEE.
3. TEE Execution: TEE processes the encrypted input (e.g., training or report generation).
4. Output Delivery: TEE returns result along with attestation to Oracle.
5. Blockchain Upload: Oracle uploads result and proof to  blockchain.
6. Bank A Access: Bank A retrieves the result from the blockchain for further encrypted analysis.

**TEE Attestation and Trust Establishment**:
1. TLS Setup: Oracle establishes a secure TLS channel with the TEE.
2. Challenge Sent: Oracle sends a remote attestation challenge to the TEE.
3. Attestation Response: The TEE responds with a proof and computation result.
4. Verification: Oracle verifies the TEE attestation result to ensure trusted execution.

### Blockchain Network Architecture Setup
The architecture is primarily implemented using Bash scripts and includes three main processes: network **initialization**, **channel creation**, and **chaincode deployment**.  
Our team has developed two versions of the network architecture (v1 and v2), both using Docker containers to simulate a multi-organization consortium blockchain scenario for testing and implementation purposes. 
#### v1: Development Version
Designed for rapid testing and development environments. All nodes use identical configurations and default paths, with different ports simulating connections across organizations. Simplified settings allow for quick startup and teardown.

#### v2: Simulated Production Deployment
Each node can be launched and operated independently. It supports individual configuration file paths (e.g., key generation and storage locations), offering greater flexibility and scalability, making it closer to real-world multi-organization deployment needs.

#### Network Initialization

This step focuses on container generation and interface parameter setup. However, the blockchain itself is not connected yet. Each organization sets up its local node and connection ports independently. In v2, parameters can be flexibly adjusted, allowing users to configure the network freely.  
Each organization launches the following containers:

- **Peer Node Container**: Acts as the interface for users to interact with the blockchain.
- **Certificate Authority (CA) Container**: Handles certificate issuance and identity management. We use Fabric-CA across the project, though it can be replaced with other CA solutions if needed.
- **CouchDB Container (Optional)**: Supports state data query and sorting with complex query capabilities.

The v2 architecture allows container startup and connection parameters to be configured independently for each organization, achieving high modularity and configurability.


#### Channel Creation

Before creating a channel, ensure that all participating organizations have successfully launched their network environments. One party must initiate the network to create the **genesis block**.  
At this step, the organizational members, communication addresses, and endorsement policies must be defined — these settings are critical and cannot be changed afterward.  
Subsequently, each peer must join the channel based on the predefined consensus. Once the channel is successfully created, chaincode can be installed and invoked.


#### Chaincode Deployment

Once the network and channel are ready, smart contracts (chaincode) can be deployed. All contracts in this project are written in **Go**, and the deployment process includes:

1. **Package Chaincode**: Bundle the smart contract code into a deployable format.
2. **Install Chaincode**: Each peer node must individually execute the installation.
3. **Approve Chaincode**: Nodes must sign and approve the chaincode according to the endorsement policy.
4. **Commit Chaincode**: Any node can initiate the commit; if endorsements meet the policy, the smart contract is officially added to the blockchain.
5. **Verify Deployment**: Use the `queryCommitted` command to confirm the deployment status and consistency among nodes.

#### Summary

This modular script design covers network setup, node initialization, channel creation, and chaincode deployment. It uses parameterized and templated scripting to support flexible and realistic cross-organization deployment. This makes it easier for developers to quickly switch between test and production scenarios.  
With this setup, the network architecture is fully functional. Next, we will discuss the design and implementation strategies for smart contract logic used by our team.

### Fabric Gateway Client
![chaincode](https://github.com/user-attachments/assets/45ae134f-bd64-494a-b5e3-7cb8947a102c)

After the network setup and chaincode deployment are completed, the Fabric Gateway Client (FGC) acts as an intermediary layer to communicate between the dashboard backend server and the underlying blockchain network. It is responsible for invoking smart contracts running on the underlying network. FGC also handles the training process and communicates with the TEE training environment. FGC is developed using the Hyperledger Fabric Gateway Client API in Go.

#### Training Process Description

The training process is illustrated in Figure X. Training members are divided into initiators and participants. The following flowchart describes the initiator's training process.

- **Step 0:** The initiator sends a training start signal via the dashboard.
- **Step 1:** The dashboard backend sends a request to FGC’s `/start_upload` endpoint.
- **Step 2:** FGC sends a request to the Enclave-Server to create a new training session and receives an attestation from the Enclave-Server.
- **Step 3:** FGC returns the attestation to the requester in Step 1, proving the integrity and authenticity of the Enclave-Server.
- **Step 4:** After the user uploads training data to the dashboard backend, the data is sent to FGC via `/upload_data`, and simultaneously, FGC registers the user as a training member to the training environment via `/train_member`.
- **Step 5:** After all participants have uploaded their data, a request to end uploading is sent to FGC via `/end_upload`. When handling this request, FGC queries the Enclave-Server for the list of training members through `/member_lst`.
- **Step 6:** Upon receiving the `/member_lst` request, the Enclave-Server recognizes that the upload phase is completed and starts pulling data from the blockchain by sending a `/get_data` request to FGC. FGC invokes the smart contract to fetch data from the chain and returns it to the Enclave-Server, which then begins training.
- **Step 7:** After training completes, the Enclave-Server sends the trained model, model hash, and its signature to FGC via the `/model` request. FGC then calls the smart contract to record the training information on the blockchain.

The above describes the complete training flow for the initiator. For participants, at Step 0, the dashboard notifies them of the training initiation, allowing them to decide whether to join. Participants then follow the same steps by registering as training members to the initiator’s Enclave-Server, uploading data to their own FGC, and finally viewing the training results and downloading the model through the dashboard.

#### Additional FGC APIs for Dashboard Blockchain Information

| API Endpoint       | Description                          |
|--------------------|------------------------------------|
| `/start_upload`    | Start training process              |
| `/upload_data`     | Upload training data                |
| `/end_upload`      | End the upload phase                |
| `/get_data`        | Provide training data to Enclave-Server |
| `/latest_predict`  | Accuracy of the latest model       |
| `/model_efficiency`| Difference between today's and 30-day average model inference |
| `/train_session`   | Indicates if there is a new training session |
| `/session_contrib` | Number of training sessions contributed by each organization |
| `/data_contrib`    | Proportion of training data contributed by each organization |
| `/latest_train`    | Details of the latest model training |

### User Interface
![螢幕擷取畫面 2025-06-01 130308](https://github.com/user-attachments/assets/14ec2651-e557-4ba7-8bd4-a3bbbe18f4dc)


The user interface of this project (hereinafter referred to as the "Dashboard") is implemented using React combined with TypeScript. It mainly consists of two functional blocks: **Training Data Overview and Analysis** and **Model Training Operation Management**. The overall design targets internal enterprise data analysts and governance personnel who generally do not have a programming background. Therefore, the interface focuses on data browsing, simple uploads, and starting the training process without involving any complex commands or development operations.

#### Training Information Overview

On the dashboard homepage, we present key information and an overview analysis of the overall model training, including:

- Model accuracy  
- Training time and date  
- Contributors  
- Number of model downloads  
- Download link for model files  

Additionally, considering the highly variable and time-sensitive nature of fraud tactics, this project plans to integrate with the internal databases of financial institutions for real-time prediction on recent daily data. It will compare the number of alerts in the past month and display the percentage change in alert counts, serving as a basis for retraining the model. Users can select the specific model version they wish to apply for prediction via a radio button control at the bottom of the interface.

#### Organizational Contribution Visualization

To enhance transparency and fairness in multi-party collaboration, the dashboard also includes two contribution analysis charts:

1. **Data Upload Proportion Chart:** Statistics on the number and proportion of training data uploaded by each organization.  
2. **Model Training Execution Proportion Chart:** Statistics on the frequency and proportion of model training executions performed by each organization.  

Through these visualization tools, organizational managers can monitor each participating unit’s level of engagement in data sharing and model contribution in real time. This information can serve as a basis for rewards or resource allocation and improve the overall trustworthiness and willingness to collaborate within the consortium blockchain.




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


## Using our system
### Nelong-Network framework
The network is based on the framework of [[1]Fabric Hyperledger samples][ref1]. And see more about fabric hyperledger at [[2]Hyperledger Docs][ref2]

#### Before start
First, clone the `nelong-network` folder and enter it. Then, you might want to use `chmod -R +x ./` to manage execution permissions.  
There are several common commands designed in this network. For more parameter settings, you can view the help info using `./network.sh <any_mode> -h`.

#### Start and Terminate the Network
* **Start network**: `./network.sh up`
* **Terminate network**: `./network.sh down`
* **Reopen network**: `./network.sh restart`

In fact, the number of organizations in the original test-network is based on a **hardcoded numbering** system. We change it in our project, you can select the number by the `-nan` (number and name) flag, like:  
  `./network.sh up -nan 3 Nihow Hi GoodMorning` or `./network.sh restart -nan 3 Nihow Hi GoodMorning`.

See more details with `./network.sh up -h`, `./network.sh down -h`, or `./network.sh restart -h`.

> When testing, I recommend using `./network.sh restart`, which simply combines `down` and `up` in one command.

#### Create channel
After starting your network, you can create your first channel by using:
  `./network.sh createChannel -c <channelName>`  

See more details with `./network.sh createChannel -h`.

#### Deploy your smart contract
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

### GUI
This interface is designed in React and Typescript with the [[3]sample][ref3]. You need to get into file `frontend`, then you can run up by `npm install` and `npm run dev`.


## reference
* <a id="ref1">[1]</a> Fabric Hyperledger samples: https://github.com/hyperledger/fabric-samples
* <a id="ref2">[2]</a> Hyperledger Fabric Documentation: https://hyperledger-fabric.readthedocs.io/en/latest/index.html
* * <a id="ref3">[3]</a> material kit react: https://github.com/devias-io/material-kit-react

[ref1]: #ref1
[ref2]: #ref2
[ref3]: #ref3
.
.
