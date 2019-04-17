pragma solidity ^0.5.0;

//import '../interfaces/HSTControlService.sol';
import './SnowflakeOwnable.sol';
//import '../zeppelin/ownership/Ownable.sol';

// DONE
// create default categories
// add categories - onlySnowflakeOwnable
// add services for a token
// replace services for a token
// create contract SnowflakeOwnable and modifier onlySnowflakeOwner

// TODO
// create modifier afterEndOfIssuance

// add services for a token - afterEndOfIssuance
// record authorizations in IdentityRegistryInterface.sol

// replace services for a token - afterEndOfIssuance
// record authorizations in IdentityRegistryInterface.sol

// retrieve all services by category name (example: "KYC")
// retrieve all services by token address
// retrieve all tokens by service address


/**
 * @title HSTServiceRegistry
 * @notice A service registry to hold adresses of service contracts for each security token
 * @dev The Service Registry contract has an array of token address, and provides of service providers for tokens, this simplifies the creation of an ecosystems of service providers.
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTServiceRegistry is SnowflakeOwnable {

  // service category symbol => category description
  mapping(bytes32 => string) serviceCategories;

  // token address => service category symbol => service address
  mapping(address => mapping(bytes32 => address)) public serviceRegistry;

  /**
   * @notice Triggered when category is added
   */
  event AddCategory(bytes32 _name, string _description);

  /**
   * @notice Triggered when service address is added
   */
  event AddService(address _token, bytes32 _category, address service);

  /**
   * @notice Triggered when service address is replaced
   */
  event ReplaceService(address _token, bytes32 _category, address _oldService, address _newService);

  /**
   * @dev Validate that a contract exists in an address received as such
   * Credit: https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol#L107-L114
   * @param _addr The address of a smart contract
   */
  modifier withContract(address _addr) {
    uint length;
    assembly { length := extcodesize(_addr) }
    require(length > 0);
    _;
  }

  /**
   * @notice Constructor
   * @dev    Create basic service categories
   */
  constructor() public {
    // create default categories
    serviceCategories["KYC"]   = "Know Your Customer";
    emit AddCategory("KYC", "Know Your Customer");
    serviceCategories["AML"]   = "Anti Money Laundering - Origin of funds";
    emit AddCategory("AML", "Anti Money Laundering - Origin of funds");
    serviceCategories["CFT"]   = "Counter Financing of Terrorism - Destination of funds";
    emit AddCategory("CFT", "Counter Financing of Terrorism - Destination of funds");
    serviceCategories["LEGAL"] = "Legal advisor for issuance";
    emit AddCategory("LEGAL", "Legal advisor for issuance");
  }

  /**
   * @notice Add a new service category
   * @dev    This method is only callable by the contract's owner
   * @param _name Name of the new service category
   * @param _description Description of the new service category
   */
  function addCategory(bytes32 _name, string memory _description) onlySnowflakeOwner public {
    serviceCategories[_name] = _description;
    emit AddCategory(_name, _description);
  }

  /**
   * @notice Add a new service
   *
   * @param _token Address of the token that will use the service
   * @param _category Name of the category the service belongs to
   * @param _service Address of the service to use
   */
  function addService(bytes32 _categoryName, address _service) withContract(_tokenAddress) withContract(_service) public {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0);
    address _tokenAddress = msg.sender;
    serviceRegistry[_tokenAddress][_categoryName] = _service;
    emit AddService(_tokenAddress, _categoryName, _service);
  }

    /**
   * @notice Replaces the address pointer to a service for a new address
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _token Address of the token that will use the service
   * @param _category Name of the category the service belongs to
   * @param _oldService Old address for the service
   * @param _newService New address for the service to use
   */
  function replaceService(bytes32 _categoryName, address _oldService, address _newService) onlyOwner withContract(_token) withContract(_newService) public {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0);
    address _tokenAddress = msg.sender;
    serviceRegistry[_tokenAddress][_categoryName] = _newService;
    emit ReplaceService(_tokenAddress, _categoryName, _oldService, _newService);
  }

}
