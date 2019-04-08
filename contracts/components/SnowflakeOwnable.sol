pragma solidity ^0.5.4;

import '../interfaces/IdentityRegistryInterface.sol';

// DONE
// import relevant Snowflake contract
// contructor
// function isOwner()

// TO DO

// record Rinkeby contract address for relevant Snowflake contract

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

    // event OwnershipTransferred(
    //     address indexed previousOwner,
    //     address indexed newOwner
    // );
    event OwnershipTransferred(uint previousOwnerEIN, uint newOwnerEIN);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor(address _identityRegistryAddress) public {
        require(_identityRegistryAddress != address(0), 'The identity registry address is required');
        identityRegistry = IdentityRegistryInterface(_identityRegistryAddress);
        //_owner = msg.sender;
        ownerEIN = identityRegistry.getEIN(msg.sender);
        emit OwnershipTransferred(0, ownerEIN);
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(uint) {
        return ownerEIN;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
        uint caller = identityRegistry.getEIN(msg.sender);
        return (caller == ownerEIN);
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(ownerEIN, 0);
        ownerEIN = 0;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner EIN to transfer ownership to.
    */
    function transferOwnership(uint _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner EIN to transfer ownership to.
    */
    function _transferOwnership(uint _newOwner) internal {
        require(_newOwner != 0);
        emit OwnershipTransferred(ownerEIN, _newOwner);
        ownerEIN = _newOwner;
    }
}
