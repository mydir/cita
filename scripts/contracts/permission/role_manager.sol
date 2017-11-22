pragma solidity ^0.4.14;

import "./util.sol";

/// @title Manager the role 
library RoleManager {

    using Util for *;

    struct Roles {
        mapping(bytes32 => Role) roles;
    }

    struct Role {
        bytes32 name;
        bytes32[] permissions;
    }

    event RoleNewed(bytes32 indexed _name);
    event NameModified(bytes32 indexed _oldName, bytes32 indexed _newName);
    event PermissionsAdded(bytes32 indexed _name, bytes32[] _permissions);
    event PermissionsDeleted(bytes32 indexed _name, bytes32[] _permissions);
    event RoleDeleted(bytes32 indexed _name);
    event RoleInited(bytes32 indexed _name, bytes32[] _permissions);

    /// @dev Init a basic role
    /// @return The basic role
    function initRole(
        Roles storage self,
        bytes32 _basic,
        bytes32[] _permissions
    )
        internal
        returns(bool)
    {
        self.roles[_basic].name = _basic;
  
        for (uint i = 0; i < _permissions.length; i++)
            self.roles[_basic].permissions[i] = _permissions[i];

        RoleInited(_basic, _permissions);
        return true;
    }

    /// @dev New a role
    /// @param _name The role name of the caller
    /// @return The new role name
    function newRole(
        Roles storage self,
        bytes32 _name,
        bytes32 _newName,
        bytes32[] _newPermissions,
        Util.SetOp _op
    )
        internal 
        returns (bool) 
    {
        self.roles[_newName].name = _newName;

        if (Util.SetOp.None == _op) {
            for (uint i = 0; i < _newPermissions.length; i++)
                self.roles[_newName].permissions[i] = _newPermissions[i];
        } else {
            bytes32[] memory one = Util.setOpBytes32(self.roles[_name].permissions, _newPermissions, _op);
            for (uint j = 0; j < one.length; j++)
                self.roles[_newName].permissions[j] = one[j];
        }

        RoleNewed(_newName);
        return true;

    }

    /// @dev Modify the name
    function modifyName(Roles storage self, bytes32 _oldName, bytes32 _newName) internal returns (bool) {
        Role memory role = self.roles[_oldName];
        role.name = _newName;
        self.roles[_newName] = role;
        delete self.roles[_oldName];
        NameModified(_oldName, _newName);
        return true;

    }

    /// @dev Add permissions 
    function addPermissions(Roles storage self, bytes32 _name, bytes32[] _permissions) internal returns (bool) {
        bytes32[] memory result = Util.opUnionBytes32(self.roles[_name].permissions, _permissions);

        for (uint i = 0; i < result.length; i++)
            self.roles[_name].permissions[i] = result[i];

        PermissionsAdded(_name, _permissions);
        return true;

    }

    /// @dev Delete permissions 
    function deletePermissions(Roles storage self, bytes32 _name, bytes32[] _permissions) internal returns (bool) {
        bytes32[] memory result = Util.opDiffBytes32(self.roles[_name].permissions, _permissions);

        for (uint i = 0; i < result.length; i++)
            self.roles[_name].permissions[i] = result[i];

        PermissionsDeleted(_name, _permissions);
        return true;
 
    }

    /// @dev Delete role
    function deleteRole(Roles storage self, bytes32 _name) internal returns (bool) {
        delete self.roles[_name];
        RoleDeleted(_name);
        return true;
    }
}
