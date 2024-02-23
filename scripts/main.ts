import { ethers, network } from 'hardhat';
import { appendFileSync } from 'fs';
import { join } from 'path';
import { verify } from './staking';

export async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('DEPLOYING CONTRACT WITH THE ACCOUNT :', deployer.address);

  // console.log('DEPLOYER ACCOUNT BALANCE:', (await deployer.getBalance()).toString());
  // getting contract namespaces
  const GREENLERSSTAKINGFACTORY = await ethers.getContractFactory('GreenlersStaking');

  const GREENLERSSTAKING = await GREENLERSSTAKINGFACTORY.deploy(`0x96c694b644E215BDD025E050EDf9cE9b018bCcDB`);

  await GREENLERSSTAKING.deployed();

  // wait after 6 confirmations to verify properly
  await GREENLERSSTAKING.deployTransaction.wait(6);

  // verify contract
  await verify(GREENLERSSTAKING.address, [`0x96c694b644E215BDD025E050EDf9cE9b018bCcDB`]);

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
import { ethers, network } from 'hardhat';
import { appendFileSync } from 'fs';
import { join } from 'path';
import { verify } from './staking';

export async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('DEPLOYING CONTRACT WITH THE ACCOUNT :', deployer.address);

  // console.log('DEPLOYER ACCOUNT BALANCE:', (await deployer.getBalance()).toString());
  // getting contract namespaces
  const GREENLERSSTAKINGFACTORY = await ethers.getContractFactory('GreenlersStaking');

  const GREENLERSSTAKING = await GREENLERSSTAKINGFACTORY.deploy(`0x96c694b644E215BDD025E050EDf9cE9b018bCcDB`);

  await GREENLERSSTAKING.deployed();

  // wait after 6 confirmations to verify properly
  await GREENLERSSTAKING.deployTransaction.wait(6);

  // verify contract
  await verify(GREENLERSSTAKING.address, [`0x96c694b644E215BDD025E050EDf9cE9b018bCcDB`]);

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
