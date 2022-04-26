pub contract MerkleProof {

    pub fun verifyProof(proof: [[UInt8]], root: [UInt8], leaf: [UInt8], hasherRawValue: UInt8): Bool {
        pre {
            proof.length > 0: "invalid proof"
            root.length == 32: "invalid root"
            leaf.length == 32: "invalid leaf"
        }

        for p in proof {
            if p.length != 32 {
                panic("invalid proof")
            }
        }

        let hasher = HashAlgorithm(rawVaule: hasherRawValue) ?? panic("invalid hasher")

        var computedHash = leaf
        var counter = 0
        while counter < proof.length {
            let proofElement = proof[counter]
            if self.compareBytes(proofElement, computedHash) == 1 {
                computedHash = hasher.hash(computedHash.concat(proofElement))
            } else {
                computedHash = hasher.hash(proofElement.concat(computedHash))
            }

            counter = counter + 1
        }

        return self.compareBytes(computedHash, root) == 0
    }

    priv fun compareBytes(_ b1: [UInt8], _ b2: [UInt8]): Int8 {
        pre {
            b1.length == 32: "invalid params"
            b2.length == 32: "invalid params"
        }
        
        var counter = 0
        while counter < b1.length {
            let diff = Int32(b1[counter]) - Int32(b2[counter])
            if diff > 0 {
                return 1
            }

            if diff < 0 {
                return -1
            }

            counter = counter + 1
        }

        return 0
    }
}