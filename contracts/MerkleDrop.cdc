import FlowToken from "./FlowToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
import MerkleProof from "./MerkleProof.cdc"

pub contract MerkleDrop {
    pub let merkleRoot: [UInt8]
    priv let vault: @FlowToken.Vault
    priv let claimRecords: {Address: Bool}

    pub event Claimed(address: Address, amount: UFix64)

    init(merkleRoot: [UInt8]) {
        self.merkleRoot = merkleRoot
        self.vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        self.claimRecords = {}
    }

    pub fun deposit(from: @FungibleToken.Vault) {
        let v <- from as! @FlowToken.Vault
        self.vault.deposit(from: <- v)
    }

    pub fun balance(): UFix64 {
        return self.vault.balance
    }

    pub fun claim(address: Address, amount: UFix64, proof: [[UInt8]]) {
        if self.claimRecords[address] == true {
            panic("already claimed")
        }

        let payload = String.encodeHex(address.toString().concat(":").concat(amount.toString()).utf8)
        let leaf = HashAlgorithm.KECCAK_256.hash(payload.utf8)

        let isValid = MerkleProof.verifyProof(
            proof: proof, 
            root: self.merkleRoot, 
            leaf: leaf, 
            hasherRawValue: HashAlgorithm.KECCAK_256.rawValue
        )

        if !isValid {
            panic("invalid proof")
        }

        let receiver = getAccount(address).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()
            ?? panic("Could not get Receiver capability")

        let sentVault <- self.vault.withdraw(amount: amount)
        receiver.deposit(from: <- sentVault)

        self.claimRecords[address] = true
        emit Claimed(address: address, amount: amount)
    }
}