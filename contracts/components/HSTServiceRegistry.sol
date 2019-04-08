pragma solidity ^0.5.4;

import './HSTControlService.sol';
import './SnowflakeOwnable.sol';

// DONE
// create default categories
// add categories
// add services for a token
// replace services for a token
// create contract SnowflakeOwnable and modifier onlySnowflakeOwner
// TODO
// create modifier afterEndOfIssuance

// add services for a token - onlySnowflakeOwner and afterEndOfIssuance
// record authorizations in IdentityRegistryInterface.sol

// replace services for a token - onlySnowflakeOwner and afterEndOfIssuance
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

  // category symbol => category description
  mapping(bytes32 => string) serviceCategories;

  // token address => service category => service address
  mapping(address => mapping(bytes32 => address)) public serviceRegistry;

  /**
   * @notice Triggered when service address is added or replaced
   */
  event AddCategory(bytes32 name, string description);
  event AddService(address token, bytes32 category, address service);
  event ReplaceService(address token, bytes32 category, address oldService, address newService);

  /**
   * @dev Validate contract address
   * Credit: https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol#L107-L114
   *
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
   *
   */
  function ServiceRegistry() public {
    // create default categories
    serviceCategories["KYC"]   = "Know Your Customer";
    AddCategory("KYC", "Know Your Customer");
    serviceCategories["AML"]   = "Anti Money Laundering - Origin of funds";
    AddCategory("AML", "Anti Money Laundering - Origin of funds");
    serviceCategories["CFT"]   = "Counter Financing of Terrorism - Destination of funds";
    AddCategory("CFT", "Counter Financing of Terrorism - Destination of funds");
    serviceCategories["LEGAL"] = "Legal advisor for issuance";
    AddCategory("LEGAL", "Legal advisor for issuance");
  }

  /**
   * @notice Add a new service
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _name Name of the new service category
   * @param _description Description of the new service category
   */
  function addCategory(bytes32 _name, string _description) onlyOwner public {
    serviceCategories[_name] = _description;
    AddCategory(_name, _description);
  }

  /**
   * @notice Add a new service
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _token Address of the token that will use the service
   * @param _category Name of the category the service belongs to
   * @param _service Address of the service to use
   */
  function addService(address _token, bytes32 _category, address _service) onlyOwner withContract(_token) withContract(_service) public {
    serviceRegistry[_token][_category] = _service;
    AddService(_token, _category, _service);
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
  function replaceService(address _token, bytes32 _category, address _oldService, address _newService) onlyOwner withContract(_token) withContract(_newService) public {
    serviceCategories[_token][_category] = _newService;
    ReplaceService(_token, _category, _oldService, _newService);
  }

}
