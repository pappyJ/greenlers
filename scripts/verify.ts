import hardhat from 'hardhat';

import { exit } from 'process';

require('dotenv');

async function main() {
  // verify contract
  await verify('0x794D8F240fb04311bd8e0bF7e5e5Ab7e665FE15D', [`0x55d398326f99059fF775485246999027B3197955`]);
}

const verify = async (contractAddress: string, args: Array<String | boolean | number>) => {
  console.log('Verifying contract...');
  try {
    await hardhat.run('verify:verify', {
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

main()
  .then(() => exit(0))
  .catch((error) => {
    console.error(error);

    exit(1);
  });
