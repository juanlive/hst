pragma solidity ^0.5.4;

import './HydroSecuritiesToken.sol';
import './HSTIssuer.sol';
import './components/HSTEscrow.sol';
import './components/SnowflakeOwnable.sol';
import './interfaces/IdentityRegistryInterface.sol';

 /*********************************
 * Hydro addresses on Rinkeby blockchain
 *********************************
 *
 * Token contract Rinkeby: 
 * 0x4959c7f62051d6b2ed6eaed3aaee1f961b145f20
 * Nº decimals: 18
 * Symbol: HYDRO
 *
 * Snowflake contract Rinkeby
 * 0xb0d5a36733886a4c5597849a05b315626af5222e
 *
 * IdentityRegistry contract Rinkeby
 * 0xa7ba71305be9b2dfead947dc0e5730ba2abd28ea
 *
 */

/**
 * @title HSTFactory
 * @notice Perform deployment of contracts for the issuance of Hydro Securities
 * @dev 
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTFactory is SnowflakeOwnable {

    address token;
    address issuer;
    address escrow;

   /**
   * @notice Constructor
   */
    constructor() public {
    }

   /**
    * @notice Get a Hydro Securities Token deployed address
    * @dev    
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function getSecuritiesTokenAddress(bytes32 _tokenName) public returns(address) {
    }

    /**
    * @notice Triggered when a whole set of contracts for a hydro securities token deploy is started
    */
    event SecuritiesDeployStarted(bytes32 _tokenName);

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
    * @dev    
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deploySecuritiesTokenContractSet(bytes32 _tokenName) public payable onlySnowflakeOwner returns(bool) {
      emit SecuritiesDeployStarted(_tokenName);
      token = deployToken;
      issuer = deployIssuer;
      escrow = deployEscrow;
      emit SecuritiesDeployFinished(_tokenName);
    }

    /**
    * @notice Deploy a Hydro Securities Token contract
    * @dev    
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deployToken(bytes32 _tokenName) public payable onlySnowflakeOwner returns(address) {
      HydroSecuritiesToken _token = (new HydroSecuritiesToken).value(msg.value)(address(msg.sender));
      emit ContractDeployed(_tokenName, "TOKEN", _token);
      return _token;
    }

    /**
    * @notice Deploy a Hydro Securities Issuer contract
    * @dev    
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deployIssuer(bytes32 _name) public payable onlySnowflakeOwner returns(address) {
      HSTIssuer _issuer = (new HSTIssuer).value(msg.value)(address(msg.sender));
      emit ContractDeployed(_name, "ISSUER", _issuer);
      return _issuer;
    }

    /**
    * @notice Deploy a Hydro Securities Escrow contract
    * @dev    
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deployEscrow(bytes32 _name) public payable onlySnowflakeOwner returns(address) {
      HSTEscrow _escrow = (new HSTEscrow).value(msg.value)(address(msg.sender));
      emit ContractDeployed(_name, "ESCROW", _escrow);
      return _escrow;
    }

}
