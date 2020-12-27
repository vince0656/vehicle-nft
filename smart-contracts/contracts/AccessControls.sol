// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";

// todo; natspec
contract AccessControls is AccessControl {
    bytes32 public constant GARAGE_ROLE = bytes32("GARAGE_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function isAdmin(address _account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function isGarage(address _account) external view returns (bool) {
        return hasRole(GARAGE_ROLE, _account);
    }

    function grantAdminRoleTo(address _recipient) external {
        grantRole(DEFAULT_ADMIN_ROLE, _recipient);
    }

    function grantGarageRoleTo(address _recipient) external {
        grantRole(GARAGE_ROLE, _recipient);
    }
}
