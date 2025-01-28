import { Addressable } from "ethers";
import hre from "hardhat";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { Wallet, Provider } from "zksync-ethers";

// Then deploy the rest of the contracts: `npx hardhat deploy-zksync --script deploy.ts --network zkSyncMainnet/zkSyncTestnet`
export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const provider = new Provider(hre.network.config.url);
  const deployerAddressPV = new Wallet(process.env.PV_KEY as string).connect(provider);
  const deployerAddress = deployerAddressPV.address;

  if (!deployerAddress) {
    console.error("Please set the PV_KEY in your .env file");
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

  const safeMultisig = "0xaFeA787Ef04E280ad5Bb907363f214E4BAB9e288";

  // Deploy the SablierMerkleFactory contract
  const merkleFactory = await deployer.deploy(artifactMerkleFactory, [safeMultisig]);
  const merkleFactoryAddress =
    typeof merkleFactory.target === "string" ? merkleFactory.target : merkleFactory.target.toString();
  console.log("SablierMerkleFactory deployed to:", merkleFactoryAddress);
  await verifyContract(merkleFactoryAddress, [safeMultisig]);
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
