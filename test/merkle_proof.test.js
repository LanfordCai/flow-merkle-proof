import path from "path";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256"
import { 
  emulator, 
  init,
  getAccountAddress, 
  deployContractByName, 
  executeScript,
} from "flow-js-testing";

jest.setTimeout(5000)

describe("MerkleProof", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "..")
    const port = 8080
    await init(basePath, { port })
    await emulator.start(port)
    return await new Promise(r => setTimeout(r, 2000));
  })

  afterEach(async () => {
    await emulator.stop();
    return await new Promise(r => setTimeout(r, 2000));
  })

  it("should return true for a valid Merkle proof", async function() {
    await deployContracts();
    const elements = ["e", "a", "b", "c", "d"].map((e) => keccak256(e));
    const merkleTree = new MerkleTree(elements, keccak256, { sortPairs: true });

    const leaf = elements[0]
    const root = merkleTree.getRoot().toJSON().data;
    const proof = merkleTree.getProof(leaf).map((e) => e.data.toJSON().data);

    const [result, err] = await verify(proof, root, leaf.toJSON().data, 6)
    expect(err).toBeNull()
    expect(result).toBeTruthy()
  });

  it("should return false for an invalid Merkle proof", async function() {
    await deployContracts();
    const correctElements = ["a", "b", "c"].map((e) => keccak256(e));
    const correctMerkleTree = new MerkleTree(correctElements, keccak256, { sortPairs: true });

    const correctRoot = correctMerkleTree.getRoot().toJSON().data;

    const correctLeaf = correctElements[0].toJSON().data;

    const badElements = ["d", "e", "f"].map((e) => keccak256(e));
    const badMerkleTree = new MerkleTree(badElements, keccak256, { sortPairs: true });

    const badProof = badMerkleTree.getProof(badElements[0]).map((e) => e.data.toJSON().data);

    const [result, err] = await verify(badProof, correctRoot, correctLeaf, 6)
    expect(err).toBeNull()
    expect(result).not.toBeTruthy()
  });

  it("should return error for a Merkle proof of invalid length", async function() {
    await deployContracts();
    const elements = ["a", "b", "c"].map((e) => keccak256(e));
    const merkleTree = new MerkleTree(elements, keccak256, { sortPairs: true });

    const root = merkleTree.getRoot().toJSON().data;

    const proof = merkleTree.getProof(elements[0]).map((e) => e.data.toJSON().data);
    const badProof = proof.slice(0, proof.length - 5);

    const leaf = elements[0].toJSON().data;

    const [result, err] = await verify(badProof, root, leaf, 6)
    expect(err).not.toBeNull()
  })
})

// Helpers

async function deployContracts() {
  const Alice = await getAccountAddress("Alice")
  await deploy(Alice, "MerkleProof")
}

async function verify(proof, root, leaf, hasher) {
  const name = "verify"
  const args = [proof, root, leaf, hasher]
  return await executeScript({name: name, args: args})
}

async function deploy(deployer, contractName) {
  const [deploymentResult, err] = await deployContractByName({ to: deployer, name: contractName})
  expect(err).toBeNull()
}