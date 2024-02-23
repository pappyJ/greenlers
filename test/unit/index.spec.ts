import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Greeter', function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory('Greeter');
    const greeter = await Greeter.deploy('Hello, world!');

    await greeter.deployed();

    expect(await greeter.greet()).to.equal('Hello, world!');

    const setGreetingTx = await greeter.setGreeting('Hola, mundo!');

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal('Hola, mundo!');
  });

  it('Successfully Added A Memeber', async () => {
    const Greeter = await ethers.getContractFactory('Greeter');

    const greetContract = await Greeter.deploy('PappyJ Is On Test Wheels!');

    await greetContract.deployed();

    await greetContract.addMember();

    console.log(await greetContract.key());

    expect(await greetContract.members(await greetContract.key())).to.equal(await greetContract.creator());
  });
});
