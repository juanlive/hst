pragma solidity ^0.5.0;

//import '../interfaces/HSTControlService.sol';
import './SnowflakeOwnable.sol';
import '../HSToken.sol';
import '../_testing/IdentityRegistry.sol';
//import '../zeppelin/ownership/Ownable.sol';


// TO DO
// review addDefaultRulesService
// Create basic service categories ?


/**
 * @title HSTServiceRegistry
 *
 * @notice A service registry to hold EINs of service providers for each security token
 *
 * @dev The Service Registry contract has an array of token address, and holds EINs of service providers for tokens, this simplifies the creation of an ecosystem of service providers.
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

  // token address => service category symbol => service provider EIN
  //mapping(address => mapping(bytes32 => uint)) public serviceRegistry;

  // token address => service provider EIN => service category symbol
  mapping(address => mapping(uint => bytes32)) public serviceRegistry;


  /**
   * @notice Triggered when category is added
   */
  event AddCategory(address _tokenAddress, bytes32 _categorySymbol, string _categoryDescription);

  /**
   * @notice Triggered when service provider is added
   */
  event AddService(address _tokenAddress, uint _serviceProviderEIN, bytes32 _serviceCategory);

  /**
   * @notice Triggered when service provider is removed
   */
  event RemoveService(address _tokenAddress, uint _oldServiceEIN);

  /**
   * @notice Constructor
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
  // modifier isContract(address _addr) {
  //   uint length;
  //   assembly { length := extcodesize(_addr) }
  //   require(length > 0, "This is not a contract");
  //   _;
  // }

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
  *
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
   *
   * @param _tokenAddress Address of the token to add service to
   * @param _categorySymbol Symbol for the new service category
   * @param _categoryDescription Description for the new service category
   */
  function addCategory(address _tokenAddress, bytes32 _categorySymbol, string memory _categoryDescription) public onlyTokenOwner(_tokenAddress) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_categorySymbol.length != 0, "Category symbol cannot be blank");
    bytes memory _categoryDescriptionTest = bytes(_categoryDescription);
    require (_categoryDescriptionTest.length != 0, "Category descrption cannot be blank");
    serviceCategories[_tokenAddress][_categorySymbol] = _categoryDescription;
    emit AddCategory(_tokenAddress, _categorySymbol, _categoryDescription);
  }

  /**
   * @notice Add a new service provider
   *
   * @param _tokenAddress Address of the token to add service to
   * @param _serviceProviderEIN EIN of the service provider to add
   * @param _categorySymbol Symbol for the category the service provider works in
   */
  function addService(address _tokenAddress, uint _serviceProviderEIN, bytes32 _categorySymbol)
    public onlyTokenOwner(_tokenAddress) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_serviceProviderEIN != 0, "Service provider EIN cannot be blank");
    require (_categorySymbol.length != 0, "Category symbol cannot be blank");
    serviceRegistry[_tokenAddress][_serviceProviderEIN] = _categorySymbol;
    emit AddService(_tokenAddress, _serviceProviderEIN, _categorySymbol);
  }

  // function addDefaultRulesService(address _tokenAddress) public onlyTokenOwner(_tokenAddress) {
  //     serviceRegistry[_tokenAddress]["RULES"] = defaultRulesEnforcerAddress;
  // }

    /**
   * @notice Remove a service provider
   *
   * @dev This method is only callable by the token owner
   *
   * @param _tokenAddress Address of the token to remove service from
   * @param _oldServiceEIN EIN of the service provider to remove
   */
  function removeService(address _tokenAddress, uint _oldServiceEIN)
    public onlyTokenOwner(_tokenAddress) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_oldServiceEIN != 0, "Old service EIN cannot be blank");
    serviceRegistry[_tokenAddress][_oldServiceEIN] = "";
    emit RemoveService(_tokenAddress, _oldServiceEIN);
  }

  /**
   * @notice Get existing service address
   *
   * @dev if checking about "RULES" services and it is blank, fill it with default
   *
   * @param _tokenAddress Address of the token to get service from
   * @param _serviceProviderEIN EIN of the service provider to get
   * @return _categorySymbol Symbol of the category the service provider works in
   */
  function getService(address _tokenAddress, uint _serviceProviderEIN)
    public view returns(bytes32 _categorySymbol) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_serviceProviderEIN != 0, "Service provider EIN cannot be zero");
    return serviceRegistry[_tokenAddress][_serviceProviderEIN];
  }

  /**
   * @notice Get existing service address
   * @dev if checking about "RULES" services and it is blank, fill it with default
   *
   * @param _tokenAddress Address of the token to check service provider existence
   * @param _serviceProviderEIN EIN of the service provider to check
   * @return _isProvider The EIN sent belongs to a provider or not
   */
  function isProvider(address _tokenAddress, uint _serviceProviderEIN)
    public view returns(bool _isProvider) {
    require (_tokenAddress != address(0), "Token address cannot be blank");
    require (_serviceProviderEIN != 0, "Service provider EIN cannot be zero");
    return serviceRegistry[_tokenAddress][_serviceProviderEIN].length > 0;
  }

}

