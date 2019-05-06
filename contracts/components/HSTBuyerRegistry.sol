pragma solidity ^0.5.0;

//import '../interfaces/HSTControlService.sol';
import './SnowflakeOwnable.sol';
import '../apis/datetimeapi.sol';
//import '../zeppelin/ownership/Ownable.sol';

// DONE


// TODO

// create structure and mapping for buyers
// adapt datetime management

// adapt KYC for multiple providers
// adapt AML for multiple providers
// create methods for managing buyers

// analyze the following:

// age restrictions
// net-worth restrictions
// salary restrictions
// country/geography restrictions on ownership
// Restricted Transfers - override normal ERC-20 transfer methods to block transfers of HST between wallets if not on a KYC/AML whitelist


/**
 * @title HSTBuyerRegistry
 * @notice A service registry to hold EINs of buyers for any security token
 * @dev The Service Registry contract has an array of EINs, holds and provides information for buyers of any token, this simplifies the management of an ecosystems of buyers.
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTBuyerRegistry is SnowflakeOwnable {

  struct buyerData {
    string  firstName;
    string  lastName;
    bytes32 isoCountryCode;
    uint8   age;
    uint64  netWorth;
    uint32  salary;
  }

  // buyer EIN => buyer data
  mapping(uint => buyerData) public buyerRegistry;

  // buyer EIN => token address => service category for KYC provider
  mapping(uint => mapping(address => bytes32)) public kycDetailForBuyers;

  // buyer EIN => token address => service category for AML provider
  mapping(uint => mapping(address => bytes32)) public amlDetailForBuyers;


  /**
   * @notice Triggered when buyer is added
   */
  event AddBuyer(uint _buyerEIN, string _firstName, string _lastName);

  /**
   * @notice Triggered when service is added
   */
  event AddServiceToBuyer(uint _buyerEIN, address _token, bytes32 _category);

  /**
   * @notice Triggered when service is replaced
   */
  event ReplaceServiceForBuyer(uint _buyerEIN, address _token, bytes32 _oldCategory, bytes32 _newCategory);

  /**
   * @dev Validate that a contract exists in an address received as such
   * Credit: https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol#L107-L114
   * @param _addr The address of a smart contract
   */
  modifier isContract(address _addr) {
    uint length;
    assembly { length := extcodesize(_addr) }
    require(length > 0);
    _;
  }

  /**
   * @notice Constructor
   */
  constructor() public {
  }

  /**
   * @notice Add a new buyer
   * @dev    This method is only callable by the contract's owner
   * @param _name Name of the new service category
   * @param _description Description of the new service category
   */
  function addBuyer(bytes32 _name, string memory _description) onlySnowflakeOwner public {
    serviceCategories[_name] = _description;
    emit addBuyer(_name, _description);
  }

  /**
   * @notice Add a new service
   *
   * @param _service Address of the service to use
   */
  function addServiceToBuyer(bytes32 _categoryName, address _service) isContract(msg.sender) isContract(_service) public {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0);
    serviceRegistry[msg.sender][_categoryName] = _service;
    emit AddServiceToBuyer(msg.sender, _categoryName, _service);
  }

    /**
   * @notice Replaces the address pointer to a service for a new address
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _oldService Old address for the service
   * @param _newService New address for the service to use
   */
  function replaceServiceForBuyer(bytes32 _categoryName, address _oldService, address _newService) onlyOwner isContract(msg.sender) isContract(_newService) public {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0);
    serviceRegistry[msg.sender][_categoryName] = _newService;
    emit ReplaceServiceForBuyer(msg.sender, _categoryName, _oldService, _newService);
  }

}
