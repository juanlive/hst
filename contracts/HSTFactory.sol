pragma solidity ^0.5.0;

import './HSToken.sol';
import './components/SnowflakeOwnable.sol';
import './interfaces/IdentityRegistryInterface.sol';

// TO DO

// check if token exists, then check if it is active
// allow new deployment if any of both is false, if both are true reject deployment

// add mainnet addresses
// add a parameter to choose deployment network

/**
 * @title HSTFactory
 * @notice Perform deployment of contracts for the issuance of Hydro Securities
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTFactory is SnowflakeOwnable {

 /*************************************************
 * Hydro and other addresses on Rinkeby blockchain
 **************************************************/

    // DateTime contract Rinkeby
    //address public dateTimeRinkeby = 0x92482Ba45A4D2186DafB486b322C6d0B88410FE7;

    // IdentityRegistry contract Rinkeby
    //address public identityRinkeby = 0xa7ba71305bE9b2DFEad947dc0E5730BA2ABd28EA;

    // Snowflake contract Rinkeby
    //address public snowflakeRinkeby = 0xB0D5a36733886a4c5597849a05B315626aF5222E;

    // Hydro Token contract Rinkeby, 18 decimals, symbol = HYDRO
    //address public hydroTokenRinkeby = 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20;

    // name of the token => address of the token
    mapping(bytes32 => address) tokens;


 /*******************************************************
 * Hydro and other addresses that will be used to deploy
 *******************************************************/

    address dateTime;
    address identityRegistry;
    address hydroToken;

   /**
   * @notice Constructor
   */
    constructor(address _dateTime, address _identityRegistry, address _hydroToken) public {
      dateTime = _dateTime;
      identityRegistry = _identityRegistry;
      hydroToken = _hydroToken;
    }

   /**
    * @notice Get a Hydro Securities token contract deployed address
    * @param  _tokenName The name of the token contract set to be deployed
    * @return the address of the token contract corresponding to that name
    */
    function getSecuritiesTokenAddress(bytes32 _tokenName) public view returns(address) {
      return tokens[_tokenName];
    }

    /**
    * @notice Triggered when a whole set of contracts for a hydro securities token deploy is started
    */
    event SecuritiesDeployStarted(bytes32 _tokenName);

    /**
    * @notice Triggered when a whole set of contracts for a hydro securities token deploy is cancelled
    */
    event SecuritiesDeployCancelled(bytes32 _tokenName, string _reason);

    /**
    * @notice Triggered when a whole set of contracts for a hydro securities token deploy is finished
    */
    event SecuritiesDeployFinished(bytes32 _tokenName);

    /**
    * @notice Triggered when each contract is deployed
    */
    event ContractDeployed(bytes32 _name, bytes32 _type, address indexed _addr);

    /**
    * @notice Deploy a Hydro Securities Token contract set
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deploySecuritiesTokenContractSet(bytes32 _tokenName, string memory _description, string memory _symbol, uint8 _decimals)
    public payable returns(bool) {
      emit SecuritiesDeployStarted(_tokenName);
      bool _deploymentAllowed = true;
      // check if token to be deployed already exists in the list of tokens
      if ( tokens[_tokenName] != address(0) ) {
        // token exists, check if is alive
        HSToken _token = HSToken(tokens[_tokenName]);
        if ( _token.isAlive() ) {
          // token exists and it is alive, cancel deploy
          _deploymentAllowed = false;
          emit SecuritiesDeployCancelled(_tokenName, "Token exists and it is alive");
        }
      } else {
          _deploymentAllowed = false;
      }
      if ( _deploymentAllowed == true ) {
        tokens[_tokenName] = deployToken(_tokenName, _description, _symbol, _decimals);
        emit SecuritiesDeployFinished(_tokenName);
      }
    }

    /**
    * @notice Deploy a Hydro Securities Token contract
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deployToken(bytes32 _tokenName, string memory _description, string memory _symbol, uint8 _decimals)
     public onlySnowflakeOwner returns(address) {
      HSToken _token = new HSToken(1, _tokenName, _description, _symbol, _decimals, hydroToken, identityRegistry);
      address _tokenAddress = address(_token);
      tokens[_tokenName] = _tokenAddress;
      emit ContractDeployed(_tokenName, "TOKEN", _tokenAddress);
      return _tokenAddress;
    }

}
