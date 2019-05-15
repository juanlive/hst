pragma solidity ^0.5.0;

//import '../interfaces/HSTControlService.sol';
import './SnowflakeOwnable.sol';
import '../HSToken.sol';
import '../_testing/IdentityRegistry.sol';
//import '../zeppelin/ownership/Ownable.sol';


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
 *
 * @notice A service registry to hold adresses of service contracts for each security token
 *
 * @dev The Service Registry contract has an array of token address, and provides addresses of service providers for tokens, this simplifies the creation of an ecosystems of service providers.
 *
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */

contract HSTServiceRegistry is SnowflakeOwnable {

  // existing contracts to call
  address defaultRulesEnforcerAddress;
  address identityRegistryAddress;

  IdentityRegistry identityRegistry;
  HSToken token;
  uint tokenEINOwner;

  // token address => service category symbol => category description
  mapping(address => mapping(bytes32 => string)) serviceCategories;

  // token address => service category symbol => service address
  mapping(address => mapping(bytes32 => address)) public serviceRegistry;

  /**
   * @notice Triggered when category is added
   */
  event AddCategory(address _tokenAddress, bytes32 _name, string _description);

  /**
   * @notice Triggered when service address is added
   */
  event AddService(address _token, bytes32 _category, address _service);

  /**
   * @notice Triggered when service address is replaced
   */
  event ReplaceService(address _token, bytes32 _category, address _newService);

  /**
   * @notice Constructor
   * @dev    Create basic service categories
   */
  constructor(address _defaultRulesEnforcerAddress, address _identityRegistryAddress) public {
    // set default rules enforcer
    defaultRulesEnforcerAddress = _defaultRulesEnforcerAddress;
    identityRegistryAddress = _identityRegistryAddress;
  }

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
  * @notice Throws if called by any account other than the owner
  * @dev This works on EINs, not on addresses
  */
  modifier onlyTokenOwner(address _tokenAddress) {
      require(isTokenOwner(_tokenAddress), "Must be owner to call this function");
      _;
  }

  /**
  * @notice Check if caller is owner
  * @dev This works on EINs, not on addresses
  * @return true if `msg.sender` is the owner of the contract
  */
  function isTokenOwner(address _tokenAddress) public returns(bool) {
      token = HSToken(_tokenAddress);
      tokenEINOwner = token.getTokenEINOwner();
      identityRegistry = IdentityRegistry(identityRegistryAddress);
      uint _senderEIN = identityRegistry.getEIN(msg.sender);
      return (_senderEIN == tokenEINOwner);
  }

  /**
   * @notice Add a new service category
   * @dev    This method is only callable by the contract's owner
   * @param _categoryName Name of the new service category
   * @param _description Description of the new service category
   */
  function addCategory(address _tokenAddress, bytes32 _categoryName, string memory _description) public onlyTokenOwner(_tokenAddress) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_categoryName.length != 0, "Category name cannot be blank");
    serviceCategories[_tokenAddress][_categoryName] = _description;
    emit AddCategory(_tokenAddress, _categoryName, _description);
  }

  /**
   * @notice Add a new service
   *
   * @param _service Address of the service to use
   */
  function addService(address _tokenAddress, bytes32 _categoryName, address _service) public onlyTokenOwner(_tokenAddress) isContract(_service) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_categoryName.length != 0, "Category name cannot be blank");
    serviceRegistry[_tokenAddress][_categoryName] = _service;
    emit AddService(_tokenAddress, _categoryName, _service);
  }

  function addDefaultRulesService(address _tokenAddress) public onlyTokenOwner(_tokenAddress) {
      serviceRegistry[_tokenAddress]["RULES"] = defaultRulesEnforcerAddress;
  }

    /**
   * @notice Replaces the address pointer to a service for a new address
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _categoryName Category name of the service
   * @param _newService New address for the service to use
   */
  function replaceService(address _tokenAddress, bytes32 _categoryName, address _newService)
    public onlyTokenOwner(_tokenAddress) isContract(_newService) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_categoryName.length != 0, "Category name cannot be blank");
    serviceRegistry[_tokenAddress][_categoryName] = _newService;
    emit ReplaceService(_tokenAddress, _categoryName, _newService);
  }

  /**
   * @notice Get existing service address
   * @dev if checking about "RULES" services and it is blank, fill it with default
   *
   * @param _service Address of the service to use
   */
  function getService(address _tokenAddress, bytes32 _categoryName)
    public view returns(address _service) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_categoryName.length != 0, "Category name cannot be blank");
    return serviceRegistry[_tokenAddress][_categoryName];
  }

}

