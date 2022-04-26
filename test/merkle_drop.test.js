import path from "path";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256"
import Decimal from "decimal.js"
import { 
  emulator, 
  init,
  getAccountAddress, 
  deployContractByName, 
  sendTransaction,
  mintFlow,
  getFlowBalance
} from "flow-js-testing";

jest.setTimeout(5000)

describe("MerkleDrop", () => {
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

  it("should claim token successfully for a valid Merkle proof", async function() {
    const users = await getUsers()
    const elements = getElements(users)
    const merkleTree = new MerkleTree(elements, keccak256, { sortPairs: true });
    const Alice = users[0]
    await deployContracts(Alice.address, merkleTree)
    await mintFlow(Alice.address, 1000.0)
    const [, depositErr] = await deposit(Alice.address, 700.0)
    expect(depositErr).toBeNull()
    const [preBalance,] = await getFlowBalance(Alice.address)
    expect(new Decimal(preBalance).equals(300.001)).toBeTruthy()

    const leaf = elements[0]
    const proof = merkleTree.getProof(leaf).map((e) => e.data.toJSON().data)
    const [tx, claimErr] = await claim(Alice.address, Alice.address, Alice.amount, proof)
    expect(claimErr).toBeNull()
    expect(tx.events.find((e) => e.type.includes("Claimed"))).toBeTruthy()

    const [afterBalance,] = await getFlowBalance(Alice.address)
    expect(new Decimal(afterBalance).equals(900.501)).toBeTruthy()

    // should failed if someone has already claimed
    const [, claimErr2] = await claim(Alice.address, Alice.address, Alice.amount, proof)
    expect(claimErr2).not.toBeNull()
  });

  it("should claim token failed for an invalid Merkle proof", async function() {
    const users = await getUsers()
    const elements = getElements(users)
    const merkleTree = new MerkleTree(elements, keccak256, { sortPairs: true });
    const Alice = users[0]
    const Bob = users[1]
    await deployContracts(Alice.address, merkleTree)
    await mintFlow(Alice.address, 1000.0)
    const [, depositErr] = await deposit(Alice.address, 700.0)
    expect(depositErr).toBeNull()

    const [preBalance,] = await getFlowBalance(Bob.address)
    expect(new Decimal(preBalance).equals(0.001)).toBeTruthy()

    const leaf = elements[0]
    // Alice's proof
    const proof = merkleTree.getProof(leaf).map((e) => e.data.toJSON().data)
    const [, claimErr] = await claim(Bob.address, Bob.address, Bob.amount, proof)
    expect(claimErr).not.toBeNull()
    expect(claimErr.includes("invalid proof")).toBeTruthy()

    const [afterBalance,] = await getFlowBalance(Bob.address)
    expect(new Decimal(afterBalance).equals(0.001)).toBeTruthy()
  });
})

// Helpers

async function deployContracts(deployer, merkleTree) {
  const root = merkleTree.getRoot().toJSON().data;

  const [, deployProofErr] = await deployContractByName({to: deployer, name: "MerkleProof"})
  expect(deployProofErr).toBeNull()
  const [, deployDropErr] = await deployContractByName({to: deployer, name: "MerkleDrop", args: [root]})
  expect(deployDropErr).toBeNull()
}

async function getUsers() {
  const Alice = await getAccountAddress("Alice")
  const Bob = await getAccountAddress("Bob")
  const Carl = await getAccountAddress("Carl")

  return [
    {address: Alice, amount: new Decimal(600.5)},
    {address: Bob, amount: new Decimal(200.5)},
    {address: Carl, amount: new Decimal(100)}
  ]
}

function getElements(users) {
  // it seems there is a bug about `toString()` method of Address in Cadence
  // this is a workaround to fix it.
  // SEE: https://github.com/onflow/flow-js-testing/issues/67
  return users.map((u) => {
    let addr = `0x${u.address.replace("0x", "").replace(/^0+/, "")}`
    const payload = `${addr}:${u.amount.toFixed(8)}`
    return keccak256(Buffer.from(payload).toString('hex'))
  })
}

async function claim(signer, address, amount, proof) {
  const name = "claim"
  const signers = [signer]
  const args = [address, amount, proof]
  return await sendTransaction({ name: name, signers: signers, args: args })
}

async function deposit(signer, amount) {
  const name = "deposit"
  const signers = [signer]
  const args = [amount]
  return await sendTransaction({ name: name, signers: signers, args: args })
}