import { GasLogger } from "../utils/helper.js";
const {ethers} = require("hardhat")

module.exports = async ({getNamedAccounts, getChainId , deployments}) => {
    const {deploy} = deployments
    const deployer = await getNamedAccounts();
    const chainId = await getChainId();

    const onDripMarket = await ethers.getContract("OnDripMarket")

    const onDripNFTDeployment = await deploy("OnDripNFT", 
    {
        from: deployer,
        args: [onDripMarket.address],
        log: true,
    })

}

module.exports.tags = ["all", "onDripNFTDeployment"]