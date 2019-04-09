pragma solidity ^0.5.0;

import '../interfaces/IdentityRegistryInterface.sol';

// DONE
// import relevant Snowflake contract
// contructor
// function isOwner()

/**
 * @title SnowflakeOwnable
 * @notice Snowflake-based authorizations
 * @dev The SnowflakeOwnable contract has an owner EIN, and provides basic authorization control functions, not based on an address as it is usual, but based on an EIN. This simplifies the implementation of "user permissions" when using Snowflakes.
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract SnowflakeOwnable {

    //address private _owner;
    uint ownerEIN;

    // access identity registry to get EINs for addresses
    IdentityRegistryInterface public identityRegistry;

    /**
    * @notice Emit when transferring ownership
    * @param  _previousOwnerEIN The EIN of the previous owner
    * @param  _newOwnerEIN The EIN of the new owner
    */
    event OwnershipTransferred(uint _previousOwnerEIN, uint _newOwnerEIN);

    /**
    * @notice Constructor
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account
    * @param _identityRegistryAddress The address of the IdentityRegistry contract
    */
    constructor(address _identityRegistryAddress) public {
        require(_identityRegistryAddress != address(0), 'The identity registry address is required');
        identityRegistry = IdentityRegistryInterface(_identityRegistryAddress);
        //_owner = msg.sender;
        ownerEIN = identityRegistry.getEIN(msg.sender);
        emit OwnershipTransferred(0, ownerEIN);
    }

    /**
    * @notice Get EIN of the current owner
    * @dev This contracts allows you to set ownership based on EIN instead of address
    * @return the address of the owner
    */
    function getOwnerEIN() public view returns(uint) {
        return ownerEIN;
    }

    /**
    * @notice Throws if called by any account other than the owner
    * @dev This works on EINs, not on addresses
    */
    modifier onlySnowflakeOwner() {
        require(isOwner());
        _;
    }

    /**
    * @notice Check if caller is owner
    * @dev This works on EINs, not on addresses
    * @return true if `msg.sender` is the owner of the contract
    */
    function isOwner() public view returns(bool) {
        uint caller = identityRegistry.getEIN(msg.sender);
        return (caller == ownerEIN);
    }

    /**
    * @notice Allows the current owner to relinquish control of the contract
    * @dev Renouncing to ownership will leave the contract without an owner. It will not be possible to call the functions with the `onlyOwner modifier anymore.
    */
    function renounceOwnership() public onlySnowflakeOwner {
        emit OwnershipTransferred(ownerEIN, 0);
        ownerEIN = 0;
    }

    /**
    * @notice Allows the current owner to transfer control of the contract to a newOwner
    * @dev This works on EINs, not on addresses
    * @param _newOwner EIN to transfer ownership to
    */
    function transferOwnership(uint _newOwner) public onlySnowflakeOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @notice Transfers control of the contract to a newOwner
    * @dev This works on EINs, not on addresses
    * @param _newOwner EIN to transfer ownership to
    */
    function _transferOwnership(uint _newOwner) internal onlySnowflakeOwner {
        require(_newOwner != 0);
        emit OwnershipTransferred(ownerEIN, _newOwner);
        ownerEIN = _newOwner;
    }
}
