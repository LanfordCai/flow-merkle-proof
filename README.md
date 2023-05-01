# Flow Merkle Proof

Merkle Proof and Merkle Drop example for Flow/Cadence.

## Tests

Make sure you have the following `flow-cli` version, or above:

```bash
flow version

Version: v1.0.2
Commit: 5b6d176eec1c6248968f17ef4126327db2788103
```

Run the tests with:

```bash
flow test --cover test/MerkleProof_test.cdc
```

View the code coverage with:

```bash
cat coverage.json | jq '.coverage."A.01cf0e2f2f715450.MerkleProof"'
```
