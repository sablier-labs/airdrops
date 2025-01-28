import { Addressable } from "ethers";
import hre from "hardhat";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { Wallet, Provider } from "zksync-ethers";

// Compile: bun hardhat compile --network $NETWORK
// Deploy: bun hardhat deploy-zksync --network $NETWORK --script deploy.ts
// verify: bun hardhat verify --network $NETWORK $CONTRACT_ADDRESS
export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const provider = new Provider(hre.network.config.url);
  const deployerAddressPV = new Wallet(process.env.PRIVATE_KEY as string).connect(provider);
  const deployerAddress = deployerAddressPV.address;

  if (!deployerAddress) {
    console.error("Please set the PRIVATE_KEY in your .env file");
    return;
  }

  console.table({
    contract: "SablierMerkleFactory",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
  });

  const deployer = new Deployer(hre, deployerAddressPV);

  const artifactMerkleFactory = await deployer.loadArtifact("SablierMerkleFactory");

  const admineoa = "0xb1bef51ebca01eb12001a639bdbbff6eeca12b9f";

  // Deploy the SablierMerkleFactory contract
  const merkleFactory = await deployer.deploy(artifactMerkleFactory, [admineoa]);
  const merkleFactoryAddress =
    typeof merkleFactory.target === "string" ? merkleFactory.target : merkleFactory.target.toString();
  console.log("SablierMerkleFactory deployed to:", merkleFactoryAddress);
  await verifyContract(merkleFactoryAddress, [admineoa]);
}

const verifyContract = async (contractAddress: string | Addressable, verifyArgs: string[]): Promise<boolean> => {
  console.log("\nVerifying contract...");
  await new Promise((r) => setTimeout(r, 20000));
  try {
    await hre.run("verify:verify", {
      address: contractAddress.toString(),
      constructorArguments: verifyArgs,
      noCompile: true,
    });
  } catch (e) {
    console.log(e);
  }
  return true;
};
