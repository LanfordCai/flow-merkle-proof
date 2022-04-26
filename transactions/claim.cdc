import MerkleDrop from "../contracts/MerkleDrop.cdc"

transaction(to: Address, amount: UFix64, proof: [[UInt8]]) {
    prepare(acct: AuthAccount) {}

    execute {
        MerkleDrop.claim(address: to, amount: amount, proof: proof)
    }
}