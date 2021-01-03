// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Access control contract for the composable vehicle domain
/// @dev In addition to the default admin one, one further role is defined: Garage
/// @author Vincent de Almeida
/// @notice Last Updated 2 Jan 2021
contract AccessControls is AccessControl {
    bytes32 public constant GARAGE_ROLE = bytes32("GARAGE_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice View method for discovering addresses that have the admin role
    /// @param _account Address being queried
    /// @return bool True if the address has the role but False if not
    function isAdmin(address _account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice View method for discovering addresses that have the garage role
    /// @param _account Address being queried
    /// @return bool True if the address has the role but False if not
    function isGarage(address _account) external view returns (bool) {
        return hasRole(GARAGE_ROLE, _account);
    }

    /// @notice Grants the admin role to a given address
    /// @param _recipient of the new role
    function grantAdminRoleTo(address _recipient) external {
        grantRole(DEFAULT_ADMIN_ROLE, _recipient);
    }

    /// @notice Grants the garage role to a given address (authorised service partner)
    /// @param _recipient of the new role
    function grantGarageRoleTo(address _recipient) external {
        grantRole(GARAGE_ROLE, _recipient);
    }
}
