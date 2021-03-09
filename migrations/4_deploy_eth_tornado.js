/* global artifacts */
require('dotenv').config({ path: '../.env' })
const ETHTornado = artifacts.require('ETHTornado')
const Verifier = artifacts.require('Verifier')
const hasherContract = artifacts.require('Hasher')


module.exports = function(deployer, network, accounts) {
  return deployer.then(async () => {
    const { MERKLE_TREE_HEIGHT, ETH_AMOUNT } = process.env
    const verifier = await Verifier.deployed()
    const hasherInstance = await hasherContract.deployed()
    await ETHTornado.link(hasherContract, hasherInstance.address)
    let tornado0_1 = await deployer.deploy(ETHTornado, verifier.address, ETH_AMOUNT, MERKLE_TREE_HEIGHT, accounts[0])
    console.log('ETHTornado\'s 0.1 address ', tornado0_1.address)
    let tornado1_0 = await deployer.deploy(ETHTornado, verifier.address, "1000000000000000000", MERKLE_TREE_HEIGHT, accounts[0])
    console.log('ETHTornado\'s 1.0 address ', tornado1_0.address)
    let tornado10_0 = await deployer.deploy(ETHTornado, verifier.address, "10000000000000000000", MERKLE_TREE_HEIGHT, accounts[0])
    console.log('ETHTornado\'s 10.0 address ', tornado10_0.address)
    let tornado100_0 = await deployer.deploy(ETHTornado, verifier.address, "100000000000000000000", MERKLE_TREE_HEIGHT, accounts[0])
    console.log('ETHTornado\'s 100.0 address ', tornado100_0.address)
    let tornado1000_0 = await deployer.deploy(ETHTornado, verifier.address, "1000000000000000000000", MERKLE_TREE_HEIGHT, accounts[0])
    console.log('ETHTornado\'s 1000.0 address ', tornado1000_0.address)
  })
}
