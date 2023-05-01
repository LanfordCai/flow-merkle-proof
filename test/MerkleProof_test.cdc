import Test

pub var blockchain = Test.newEmulatorBlockchain()
pub var account = blockchain.createAccount()

pub fun setup() {
    blockchain.useConfiguration(Test.Configuration({
        "../contracts/MerkleProof.cdc": account.address
    }))

    let MerkleProof = Test.readFile("../contracts/MerkleProof.cdc")
    let err = blockchain.deployContract(
        name: "MerkleProof",
        code: MerkleProof,
        account: account,
        arguments: []
    )

    Test.assert(err == nil)
}

pub fun testVerifyValidProof() {
    // Arrange
    let proof = "4e2e9b85ebac4c1845f3b91a9234320527285134f8cc6968c2f8e8384481ac8d"
    let root = "3153ad6cc69469295e1378d379f7c6a674d4f2be8239b3ba3a4c5423ea2f9c82"
    let leaf = "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"
    let hasherRawValue = HashAlgorithm.KECCAK_256.rawValue
    let arguments: [AnyStruct] = [
        [proof.decodeHex()],
        root.decodeHex(),
        leaf.decodeHex(),
        hasherRawValue
    ]

    // Act
    let validProof = executeScript("../scripts/verify.cdc", arguments)

    // Assert
    Test.assert(validProof, message: "found: false")
}

pub fun testInvalidProofLength() {
    // Arrange
    let proof = "2e9b85ebac4c1845f3b91a9234320527285134f8cc6968c2f8e8384481ac8d"
    let root = "3153ad6cc69469295e1378d379f7c6a674d4f2be8239b3ba3a4c5423ea2f9c82"
    let leaf = "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"
    let hasherRawValue = HashAlgorithm.KECCAK_256.rawValue
    let arguments: [AnyStruct] = [
        [proof.decodeHex()],
        root.decodeHex(),
        leaf.decodeHex(),
        hasherRawValue
    ]

    // Act
    let script = Test.readFile("../scripts/verify.cdc")
    let value = blockchain.executeScript(script, arguments)

    // Assert
    Test.assert(value.status == Test.ResultStatus.failed)
}

pub fun testVerifyProofWithLowerLeaf() {
    // Arrange
    let proof = "4e2e9b85ebac4c1845f3b91a9234320527285134f8cc6968c2f8e8384481ac8d"
    let root = "3153ad6cc69469295e1378d379f7c6a674d4f2be8239b3ba3a4c5423ea2f9c82"
    let leaf = "13978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"
    let hasherRawValue = HashAlgorithm.KECCAK_256.rawValue
    let arguments: [AnyStruct] = [
        [proof.decodeHex()],
        root.decodeHex(),
        leaf.decodeHex(),
        hasherRawValue
    ]

    // Act
    let validProof = executeScript("../scripts/verify.cdc", arguments)

    // Assert
    Test.assert(!validProof, message: "found: true")
}

pub fun testVerifyWithHigherLeaf() {
    // Arrange
    let proof = "4e2e9b85ebac4c1845f3b91a9234320527285134f8cc6968c2f8e8384481ac8d"
    let root = "3153ad6cc69469295e1378d379f7c6a674d4f2be8239b3ba3a4c5423ea2f9c82"
    let leaf = "39978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"
    let hasherRawValue = HashAlgorithm.KECCAK_256.rawValue
    let arguments: [AnyStruct] = [
        [proof.decodeHex()],
        root.decodeHex(),
        leaf.decodeHex(),
        hasherRawValue
    ]

    // Act
    let validProof = executeScript("../scripts/verify.cdc", arguments)

    // Assert
    Test.assert(!validProof, message: "found: true")
}

priv fun executeScript(_ path: String, _ arguments: [AnyStruct]): Bool {
    let script = Test.readFile(path)
    let value = blockchain.executeScript(script, arguments)

    Test.assert(value.status == Test.ResultStatus.succeeded)

    return value.returnValue! as! Bool
}
