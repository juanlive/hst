pragma solidity ^0.5.0;

//import '../interfaces/HSTControlService.sol';
import './SnowflakeOwnable.sol';
import '../apis/datetimeapi.sol';
//import '../zeppelin/ownership/Ownable.sol';

// TODO

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

  //address public dateTimeAddress = 0x92482Ba45A4D2186DafB486b322C6d0B88410FE7;

  DateTime dateTime;

  struct buyerData {
    string  firstName;
    string  lastName;
    bytes32 isoCountryCode;
    uint    birthTimestamp;
    uint64  netWorth;
    uint32  salary;
  }

  struct buyerServicesDetail {
    bytes32  kycProvider;
    bytes32  amlProvider;
  }

  // buyer EIN => buyer data
  mapping(uint => buyerData) public buyerRegistry;

  // buyer EIN => token address => service details for buyer
  mapping(uint => mapping(address => buyerServicesDetail)) public serviceDetailForBuyers;


  /**
   * @notice Triggered when buyer is added
   */
  event AddBuyer(uint _buyerEIN, string _firstName, string _lastName);

  /**
   * @notice Triggered when KYC service is added
   */
  event AddKYCServiceToBuyer(uint _buyerEIN, address _token, bytes32 _serviceCategory);

  /**
   * @notice Triggered when AML service is added
   */
  event AddAMLServiceToBuyer(uint _buyerEIN, address _token, bytes32 _serviceCategory);

  /**
   * @notice Triggered when KYC service is replaced
   */
  event ReplaceKYCServiceForBuyer(uint _buyerEIN, address _token, bytes32 _serviceCategory);

  /**
   * @notice Triggered when AML service is replaced
   */
  event ReplaceAMLServiceForBuyer(uint _buyerEIN, address _token, bytes32 _serviceCategory);


  /**
   * @dev Validate that a contract exists in an address received as such
   * Credit: https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol#L107-L114
   * @param _addr The address of a smart contract
   */
  modifier isContract(address _addr) {
    uint length;
    assembly { length := extcodesize(_addr) }
    require(length > 0, "Address cannot be blank");
    _;
  }

  /**
   * @notice Constructor
   */
  constructor(address _dateTimeAddress) public {
      dateTime = DateTime(_dateTimeAddress);
  }

  /**
   * @notice Add a new buyer
   * @dev    This method is only callable by the contract's owner
   * @param _firstName First name of the buyer
   * @param _lastName Last name of the buyer
   * @param _isoCountryCode ISO country code of the buyer
   * @param _yearOfBirth Year of birth of the buyer
   * @param _monthOfBirth Month of birth of the buyer
   * @param _dayOfBirth Day of birth of the buyer
   * @param _netWorth Net worth declared by the buyer
   * @param _salary Salary declared by the buyer
  }   */
  function addBuyer(uint _buyerEIN,
                    string memory _firstName, string memory _lastName,
                    bytes32 _isoCountryCode,
                    uint16 _yearOfBirth, uint8 _monthOfBirth, uint8 _dayOfBirth,
                    uint64 _netWorth, uint32 _salary)
                    public onlySnowflakeOwner {
    buyerData _bd;
    _bd.firstName = _firstName;
    _bd.lastName = _lastName;
    _bd.isoCountryCode = _isoCountryCode;
    _bd.birthTimestamp = dateTime.toTimestamp(_yearOfBirth, _monthOfBirth, _dayOfBirth);
    _bd.netWorth = _netWorth;
    _bd.salary = _salary;
    buyerRegistry[_buyerEIN] = _bd;
    emit addBuyer(_buyerEIN, _firstName, _lastName);
  }

  /**
   * @notice Add a new KYC service for a buyer
   *
   * @param _EIN EIN of the buyer
   * @param _tokenFor Token that uses this service
   * @param _serviceCategory For this buyer and this token, the service category to use for KYC
   */
  function addKYCServiceToBuyer(uint _EIN, address _tokenFor, bytes32 _serviceCategory) public isContract(tokenFor) {
    bytes memory _emptyStringTest = bytes(_serviceCategory);
    require (_emptyStringTest.length != 0, "Service category cannot be blank");
    buyerServicesDetail[_EIN][_tokenFor].kycProvider = _serviceCategory;
    emit AddKYCServiceToBuyer(_EIN, _tokenFor, _serviceCategory);
  }

  /**
   * @notice Add a new AML service for a buyer
   *
   * @param _EIN EIN of the buyer
   * @param _tokenFor Token that uses this service
   * @param _serviceCategory For this buyer and this token, the service category to use for AML
   */
  function addAMLServiceToBuyer(uint _EIN, address _tokenFor, bytes32 _serviceCategory) public isContract(tokenFor) {
    bytes memory _emptyStringTest = bytes(_serviceCategory);
    require (_emptyStringTest.length != 0, "Service category cannot be blank");
    buyerServicesDetail[_EIN][_tokenFor].amlProvider = _serviceCategory;
    emit AddAMLServiceToBuyer(_EIN, _tokenFor, _serviceCategory);
  }

    /**
   * @notice Replaces an existing KYC service for a buyer
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _EIN EIN of the buyer
   * @param _tokenFor Token that uses this service
   * @param _serviceCategory For this buyer and this token, the service category to use for KYC
   */
  function replaceKYCServiceToBuyer(uint _EIN, address _tokenFor, bytes32 _serviceCategory) public isContract(tokenFor) {
    bytes memory _emptyStringTest = bytes(_serviceCategory);
    require (_emptyStringTest.length != 0, "Service category cannot be blank");
    buyerServicesDetail[_EIN][_tokenFor].kycProvider = _serviceCategory;
    emit ReplaceKYCServiceToBuyer(_EIN, _tokenFor, _serviceCategory);
  }

    /**
   * @notice Replaces an existing AML service for a buyer
   *
   * @dev This method is only callable by the contract's owner
   *
   * @param _EIN EIN of the buyer
   * @param _tokenFor Token that uses this service
   * @param _serviceCategory For this buyer and this token, the service category to use for KYC
   */
  function replaceAMLServiceToBuyer(uint _EIN, address _tokenFor, bytes32 _serviceCategory) public isContract(tokenFor) {
    bytes memory _emptyStringTest = bytes(_serviceCategory);
    require (_emptyStringTest.length != 0, "Service category cannot be blank");
    buyerServicesDetail[_EIN][_tokenFor].amlProvider = _serviceCategory;
    emit ReplaceAMLServiceToBuyer(_EIN, _tokenFor, _serviceCategory);
  }

}
