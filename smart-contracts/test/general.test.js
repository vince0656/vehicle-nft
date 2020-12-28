const {BN, constants, expectEvent, expectRevert, ether, balance} = require('@openzeppelin/test-helpers');
const {ZERO_ADDRESS} = constants;

const {expect} = require('chai');

const AccessControls = artifacts.require('AccessControls');
const Vehicle = artifacts.require('Vehicle');
const MOTHistory = artifacts.require('MOTHistory');

contract('General tests', function ([admin, garage, vehicleOwner, ...otherAccounts]) {
  const randomURI = 'rand';
  const randomVIN = 'VIN';

  const TOKEN_ONE_ID = new BN('1');

  beforeEach(async () => {
    this.accessControls = await AccessControls.new({from: admin});
    this.accessControls.grantGarageRoleTo(garage, {from: admin});

    this.vehicle = await Vehicle.new("Tesla", "Model S", this.accessControls.address, {from: admin});
    this.motHistory = await MOTHistory.new(this.accessControls.address, {from: admin});

    // Whitelist NFT contracts allowed to be children of vehicle
    await this.vehicle.whitelistChildContract(this.motHistory.address, {from: admin});
  });

  describe('Minting vehicle tokens', () => {
    it('Successfully mints as admin', async () => {
      await this.vehicle.mint(randomURI, randomVIN, vehicleOwner, {from: admin});

      expect(await this.vehicle.ownerOf(TOKEN_ONE_ID)).to.be.equal(vehicleOwner);
      expect(await this.vehicle.tokenURI(TOKEN_ONE_ID)).to.be.equal(randomURI);
      expect(await this.vehicle.tokenIdToVIN(TOKEN_ONE_ID)).to.be.equal(randomVIN);
    });
  });

  describe('Adding an MOT entry to a vehicle', () => {
    beforeEach(async () => {
      // Mint the first vehicle token to `vehicleOwner`
      await this.vehicle.mint(randomURI, randomVIN, vehicleOwner, {from: admin});
    });

    it('Adds an MOT entry (wraps / compose in a vehicle NFT)', async () => {
      // mot info
      const mileage = 32056;
      const pass = true;

      // mint mot nft to specific vehicle
      await this.motHistory.mint(
        this.vehicle.address,
        TOKEN_ONE_ID, //token 1 of vehicle nft
        randomURI,
        mileage,
        pass,
        "", // no advisories
        {from: garage}
      );

      expect(await this.vehicle.totalChildTokens(TOKEN_ONE_ID, this.motHistory.address)).to.be.bignumber.equal('1');
      expect(await this.vehicle.childTokenByIndex(TOKEN_ONE_ID, this.motHistory.address, '0')).to.be.bignumber.equal('1');

      const {parentTokenOwner, parentTokenId} = await this.vehicle.ownerOfChild(this.motHistory.address, TOKEN_ONE_ID);
      expect(parentTokenOwner).to.be.equal(vehicleOwner);
      expect(parentTokenId).to.be.bignumber.equal(TOKEN_ONE_ID);
    });
  });
});
