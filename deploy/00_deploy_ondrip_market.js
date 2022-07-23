import { GasLogger } from "../utils/helper.js";
const { ethers } = require("hardhat");

    require("dotenv").config();
    const gasLogger = new GasLogger();

module.exports = async ({getNamedAccounts, deployments, getChainId}) => {
    const {deploy} = deployments
    const deployer = await getNamedAccounts()
    const chainId = await getChainId();

    console.log("Chain ID:", chainId);

    const onDripMarket = await deploy("OnDripMarket", 
    {
        from: deployer,
        args: [],
        log: true,
    })

    gasLogger.addDeployment(onDripMarket);

}

module.exports.tags = ["all", "onDripMarket"]