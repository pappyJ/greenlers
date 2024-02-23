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
  const GREENLERSSTAKINGFACTORY = await ethers.getContractFactory('GreenlersStaking');

  const GREENLERSSTAKING = await GREENLERSSTAKINGFACTORY.deploy(`0x55d398326f99059fF775485246999027B3197955`);

  await GREENLERSSTAKING.deployed();

  // wait after 6 confirmations to verify properly
  await GREENLERSSTAKING.deployTransaction.wait(6);

  // verify contract

  await verify(GREENLERSSTAKING.address, [`0x55d398326f99059fF775485246999027B3197955`]);

  console.log('GREENLERS Contract DEPLOYED TO:', GREENLERSSTAKING.address);

  const config = `
  NETWORK => ${network.name}

  =====================================================================

  GREENLERS STAKING ${GREENLERSSTAKING.address}

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
