import { ethers, run } from "hardhat";

async function main() {
  // Admin address
  const initialAdmin = "0xb1bef51ebca01eb12001a639bdbbff6eeca12b9f";

  console.log("Deploying SablierMerkleFactory...");
  const sablierMerkleFactory = await ethers.getContractFactory("SablierMerkleFactory");
  const merkleFactory = await sablierMerkleFactory.deploy(initialAdmin);
  await merkleFactory.deployed();
  console.log("SablierMerkleFactory deployed to:", merkleFactory.address);

  // Verify contracts
  await verifyContract(merkleFactory.address, [initialAdmin]);
}

// Helper function to verify a contract
async function verifyContract(address: string, constructorArgs: any[]) {
  console.log(`Verifying contract at address: ${address}`);
  try {
    await run("verify:verify", {
      address,
      constructorArguments: constructorArgs,
    });
    console.log(`Contract verified successfully: ${address}`);
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log(`Contract at ${address} is already verified`);
    } else {
      console.error(`Failed to verify contract at ${address}:`, error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
