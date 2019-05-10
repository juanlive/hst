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
 * @dev The Service Registry contract has an array of token address, and provides addresses of service providers for tokens, this simplifies the creation of an ecosystems of service providers.
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTServiceRegistry is SnowflakeOwnable {

  // default rules enforcer
  address defaultRulesEnforcer;

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
  event AddService(address _token, bytes32 _category, address _service);

  /**
   * @notice Triggered when service address is replaced
   */
  event ReplaceService(address _token, bytes32 _category, address _newService);

  /**
   * @dev Validate that a contract exists in an address received as such
   * Credit: https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol#L107-L114
   * @param _addr The address of a smart contract
   */
  modifier isContract(address _addr) {
    uint length;
    assembly { length := extcodesize(_addr) }
    require(length > 0, "This is not a contract");
    _;
  }

  /**
   * @notice Constructor
   * @dev    Create basic service categories
   */
  constructor(address _defaultRulesEnforcer) public {
    // set default rules enforcer
    defaultRulesEnforcer = _defaultRulesEnforcer;
    // create default categories
    serviceCategories["AML"] = "Anti Money Laundering - Origin of funds";
    emit AddCategory("AML", "Anti Money Laundering - Origin of funds");
    serviceCategories["CFT"] = "Counter Financing of Terrorism - Destination of funds";
    emit AddCategory("CFT", "Counter Financing of Terrorism - Destination of funds");
    serviceCategories["KYC"] = "Know Your Customer";
    emit AddCategory("KYC", "Know Your Customer");
    serviceCategories["LEGAL"] = "Legal advisor for issuance";
    emit AddCategory("LEGAL", "Legal advisor for issuance");
    serviceCategories["RULES"] = "Rules enforcer for Token";
    emit AddCategory("RULES", "Rules enforcer for Token");
  }

  /**
   * @notice Add a new service category
   * @dev    This method is only callable by the contract's owner
   * @param _name Name of the new service category
   * @param _description Description of the new service category
   */
  function addCategory(bytes32 _name, string memory _description) public onlySnowflakeOwner {
    serviceCategories[_name] = _description;
    emit AddCategory(_name, _description);
  }

  /**
   * @notice Add a new service
   *
   * @param _service Address of the service to use
   */
  function addService(bytes32 _categoryName, address _service) public isContract(msg.sender) isContract(_service) {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0, "Category name cannot be blank");
    serviceRegistry[msg.sender][_categoryName] = _service;
    emit AddService(msg.sender, _categoryName, _service);
  }

  function addDefaultRulesService() public isContract(msg.sender) {
      serviceRegistry[msg.sender][_categoryName] = defaultRulesEnforcer;
  }

    /**
   * @notice Replaces the address pointer to a service for a new address
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _oldService Old address for the service
   * @param _newService New address for the service to use
   */
  function replaceService(bytes32 _categoryName, address _newService) public onlyOwner isContract(msg.sender) isContract(_newService) {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0, "Category name cannot be blank");
    serviceRegistry[msg.sender][_categoryName] = _newService;
    emit ReplaceService(msg.sender, _categoryName, _newService);
  }

  /**
   * @notice Get existing service address
   * @dev if checking about "RULES" services and it is blank, fill it with default
   *
   * @param _service Address of the service to use
   */
  function getService(bytes32 _categoryName) public isContract(msg.sender) isContract(_service) returns(address _service) {
    bytes memory _emptyStringTest = bytes(serviceCategories[_categoryName]);
    require (_emptyStringTest.length != 0, "Category name cannot be blank");
    return serviceRegistry[msg.sender][_categoryName];
  }

}

