pragma solidity ^0.5.0;

import './HSToken.sol';
import './components/SnowflakeOwnable.sol';
import './interfaces/IdentityRegistryInterface.sol';

// TO DO
// check if token exists, then check if it is active
// allow new deployment if any of both is false, if both are true reject deployment

 /*********************************
 * Hydro addresses on Rinkeby blockchain
 *********************************
 *
 * Token contract Rinkeby:
 * 0x4959c7f62051d6b2ed6eaed3aaee1f961b145f20
 * Nº decimals: 18
 * Symbol: HYDRO
 *
 * DateTime contract Rinkeby
 * 0x92482Ba45A4D2186DafB486b322C6d0B88410FE7
 *
 * IdentityRegistry contract Rinkeby
 * 0xa7ba71305be9b2dfead947dc0e5730ba2abd28ea
 *
 * Snowflake contract Rinkeby
 * 0xb0d5a36733886a4c5597849a05b315626af5222e
 *
 */

/**
 * @title HSTFactory
 * @notice Perform deployment of contracts for the issuance of Hydro Securities
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTFactory is SnowflakeOwnable {

    address public HydroToken;
    address public IdentityRegistry;

    // name of the token => address of the token
    mapping(bytes32 => address) tokens;

   /**
   * @notice Constructor
   */
    constructor(address _HydroToken, address _IdentityRegistry) public {
      HydroToken = _HydroToken;
      IdentityRegistry = _IdentityRegistry;
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
    function deploySecuritiesTokenContractSet(bytes32 _tokenName, string memory _description, string memory _symbol, uint8 _decimals) public payable returns(bool) {
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
    function deployToken(bytes32 _tokenName, string memory _description, string memory _symbol, uint8 _decimals) public onlySnowflakeOwner returns(address) {
      HSToken _token = new HSToken(1, _tokenName, _description, _symbol, _decimals, HydroToken, IdentityRegistry);
      address _tokenAddress = address(_token);
      tokens[_tokenName] = _tokenAddress;
      emit ContractDeployed(_tokenName, "TOKEN", _tokenAddress);
      return _tokenAddress;
    }

}
