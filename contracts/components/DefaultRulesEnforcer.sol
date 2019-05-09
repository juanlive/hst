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
  event AddTokenData(address _tokenAddress, bytes32 isoCountryCode);

  /**
   * @notice Triggered when a country is banned for a token
   */
  event AddCountryBan(address _tokenAddress, bytes32 isoCountryCode);

  /**
   * @notice Triggered when a country ban is lifted for a token
   */
  event LiftCountryBan(address _tokenAddress);

}

