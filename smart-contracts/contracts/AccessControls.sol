// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";

// todo; natspec
contract AccessControls is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function isAdmin(address _account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function grantAdminTo(address _recipient) external {
        grantRole(DEFAULT_ADMIN_ROLE, _recipient);
    }
}
