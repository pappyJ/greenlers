import { ethers, run, network } from 'hardhat';

import { appendFileSync } from 'fs';

import { join } from 'path';

import { exit } from 'process';

require('dotenv');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('DEPLOYING CONTRACT WITH THE ACCOUNT :', deployer.address);

  // console.log('DEPLOYER ACCOUNT BALANCE:', (await deployer.getBalance()).toString());

  // getting contract namespaces
  const GREENLERSTOKENFACTORY = await ethers.getContractFactory('Greenlers');

  const GREENLERSTOKEN = await GREENLERSTOKENFACTORY.deploy();

  await GREENLERSTOKEN.deployed();

  // wait after 6 confirmations to verify properly
  await GREENLERSTOKEN.deployTransaction.wait(6);

  // verify contract

  await verify(GREENLERSTOKEN.address, []);

  console.log('GREENLERS Contract DEPLOYED TO:', GREENLERSTOKEN.address);

  const config = `
  NETWORK => ${network.name}

  =====================================================================

  GREENLERS PRESALE ${GREENLERSTOKEN.address}

  =====================================================================

  `;

  const data = JSON.stringify(config);

  appendFileSync(join(__dirname, '../contracts/addressBook.md'), JSON.parse(data));
}

main()
  .then(() => exit(0))
  .catch((error) => {
    console.error(error);

    exit(1);
  });

const verify = async (contractAddress: string, args: Array<String | boolean | number>) => {
  console.log('Verifying contract...');
  try {
    await run('verify:verify', {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e: any) {
    if (e.message.toLowerCase().includes('already verified')) {
      console.log('Already Verified!');
    } else {
      console.log(e);
    }
  }
};
