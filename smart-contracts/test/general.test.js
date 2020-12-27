const {BN, constants, expectEvent, expectRevert, ether, balance} = require('@openzeppelin/test-helpers');
const {ZERO_ADDRESS} = constants;

require('chai').should();

const AccessControls = artifacts.require('AccessControls');
const Vehicle = artifacts.require('Vehicle');

contract('General tests', function ([admin, ...otherAccounts]) {
  beforeEach(async () => {
    this.accessControls = await AccessControls.new({from: admin});
    this.vehicle = await Vehicle.new("Tesla", "Model 3", this.accessControls.address, {from: admin});
  });

  describe('Minting vehicle tokens', () => {
    it('Successfully mints as admin', async () => {
      await this.vehicle.mint("d", "d", admin, {from: admin});
    });
  });
});
