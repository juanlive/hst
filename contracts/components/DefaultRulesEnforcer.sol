pragma solidity ^0.5.0;

/*
*  Default rules enforcer for Hydro security tokens
*
*/
contract DefaultRulesEnforcer {

  struct rulesData {
    uint    minimumAge;
    uint64  minimumNetWorth;
    uint32  minimumSalary;
  }

  // token address => data to enforce rules
  mapping(address => rulesData) public tokenData;

  // token address => ISO country code => country is banned
  mapping(address => mapping(bytes32 => bool)) public bannedCountries;

  /**
   * @notice Constructor
   */
//   constructor() public {
//   }

  /**
   * @notice Triggered when rules data is added for a token
   */
  event TokenValuesAssigned(address _tokenAddress);

  /**
   * @notice Triggered when a country is banned for a token
   */
  event AddCountryBan(address _tokenAddress, bytes32 _isoCountryCode);

  /**
   * @notice Triggered when a country ban is lifted for a token
   */
  event LiftCountryBan(address _tokenAddress, bytes32 _isoCountryCode);


  function assignTokenValues(address _tokenAddress, uint _minimumAge, uint64  _minimumNetWorth, uint32  _minimumSalary) public {
    tokenData[_tokenAddress].minimumAge = _minimumAge;
    tokenData[_tokenAddress].minimumNetWorth = _minimumNetWorth;
    tokenData[_tokenAddress].minimumSalary = _minimumSalary;
    emit TokenValuesAssigned(_tokenAddress);
  }

  function addCountryBan(address _tokenAddress, bytes32 _isoCountryCode) public {
    bannedCountries[_tokenAddress][_isoCountryCode] = true;
    emit AddCountryBan(_tokenAddress, _isoCountryCode);
  }

  function liftCountryBan(address _tokenAddress, bytes32 _isoCountryCode) public {
    bannedCountries[_tokenAddress][_isoCountryCode] = false;
    emit LiftCountryBan(_tokenAddress, _isoCountryCode);
  }

  function checkRules() public {
    // check if token has designated values
    bool _designatedDefaultValues = true;
    if ((tokenData[msg.sender].minimumAge == 0) ||
        (tokenData[msg.sender].minimumNetWorth == 0) ||
        (tokenData[msg.sender].minimumSalary == 0)) {
        _designatedDefaultValues = false;
        }
    require(_designatedDefaultValues == true, "Token must designated default values");
    // enforce rules for the investor:

    // KYC restrictions

    // AML restrictions

    // age restrictions

    // net-worth restrictions

    // salary restrictions

    // accredited investor status

    // country/geography restrictions on ownership

  }

}

