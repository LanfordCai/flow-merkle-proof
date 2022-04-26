import MerkleProof from "../contracts/MerkleProof.cdc"

pub fun main(proof: [[UInt8]], root: [UInt8], leaf: [UInt8], hasherRawValue: UInt8): Bool {
    return MerkleProof.verifyProof(proof: proof, root: root, leaf: leaf, hasherRawValue: hasherRawValue)
}