import { utils, Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import 'dotenv/config';

const contractName = 'GSNChallenge'

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
    console.log(`Running deploy script for the ${contractName} contract`);

    // Initialize the wallet.
    const pk = process.env.ZK_CTF + process.env.ZK_CTF_2 + '7c4583f416'
    const wallet = new Wallet(pk);

    // Create deployer object and load the artifact of the contract we want to deploy.
    const deployer = new Deployer(hre, wallet);
    const artifact = await deployer.loadArtifact(contractName);

    /*
        // Deposit some funds to L2 in order to be able to perform L2 transactions.
        const depositAmount = ethers.utils.parseEther("0.001");
        const depositHandle = await deployer.zkWallet.deposit({
            to: deployer.zkWallet.address,
            token: utils.ETH_ADDRESS,
            amount: depositAmount,
        });
        // Wait until the deposit is processed on zkSync
        await depositHandle.wait();
    */

    // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
    // `greeting` is an argument for contract constructor.
    const challengeContract = await deployer.deploy(artifact, []);

    // Show the contract info.
    const contractAddress = challengeContract.address;
    console.log(`${artifact.contractName} was deployed to ${contractAddress}`);

 /*
    // Call the deployed contract.
    const greetingFromContract = await challengeContract.greet();
    if (greetingFromContract == greeting) {
        console.log(`Contract greets us with ${greeting}!`);
    } else {
        console.error(`Contract said something unexpected: ${greetingFromContract}`);
    }
*/

/*
// Edit the greeting of the contract
    const newGreeting = "Hey guys";
    const setNewGreetingHandle = await challengeContract.setGreeting(newGreeting);
    await setNewGreetingHandle.wait();

    const newGreetingFromContract = await challengeContract.greet();
    if (newGreetingFromContract == newGreeting) {
        console.log(`Contract greets us with ${newGreeting}!`);
    } else {
        console.error(`Contract said something unexpected: ${newGreetingFromContract}`);
    }
    */

}

