# Asset transfer basic sample

The asset transfer basic sample demonstrates:

- Connecting a client application to a Fabric blockchain network.
- Submitting smart contract transactions to update ledger state.
- Evaluating smart contract transactions to query ledger state.
- Handling errors in transaction invocation.

## About the sample

This sample includes smart contract and application code in multiple languages. This sample shows create, read, update, transfer and delete of an asset.

For a more detailed walk-through of the application code and client API usage, refer to the [Running a Fabric Application tutorial](https://hyperledger-fabric.readthedocs.io/en/latest/write_first_app.html) in the main Hyperledger Fabric documentation.

### Application

Follow the execution flow in the client application code, and corresponding output on running the application. Pay attention to the sequence of:

- Transaction invocations (console output like "**--> Submit Transaction**" and "**--> Evaluate Transaction**").
- Results returned by transactions (console output like "**\*\*\* Result**").

### Smart Contract

The smart contract (in folder `chaincode-xxx`) implements the following functions to support the application:

- CreateAsset
- ReadAsset
- UpdateAsset
- DeleteAsset
- TransferAsset

Note that the asset transfer implemented by the smart contract is a simplified scenario, without ownership validation, meant only to demonstrate how to invoke transactions.

## Running the sample

The Fabric nelong network is used to deploy and run this sample. Follow these steps in order:

1. Create the nelong network and a channel (from the `nelong-network` folder).

   ```
   ./network.sh up createChannel -c mychannel
   ```

2. Deploy one of the smart contract implementations (from the `nelong-network` folder).
    ```
    ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go/
    ```

3. Run the application (from the `asset-transfer-basic` folder).
    ```shell
    cd application-gateway-go
    go run .
    ```

## Clean up

When you are finished, you can bring down the nelong network (from the `nelong-network` folder). The command will remove all the nodes of the nelong network, and delete any ledger data that you created.

```shell
./network.sh down
```
