pragma solidity ^0.5.0;

import './HydroSecuritiesToken.sol';
import './components/HSTEscrow.sol';
import './HSTIssuer.sol';
import './components/HSTEscrow.sol';
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
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTFactory is SnowflakeOwnable {

    // name of the token => address of the token
    mapping(bytes32 => address) tokens;

    // name of the token => address of the issuer
    mapping(bytes32 => address) issuers;

    // name of the token => address of the escrow
    mapping(bytes32 => address) escrows;

   /**
   * @notice Constructor
   */
    constructor() public {
    }

   /**
    * @notice Get a Hydro Securities token contract deployed address
    * @param  _tokenName The name of the token contract set to be deployed
    * @return the address of the token contract corresponding to that name
    */
    function getSecuritiesTokenAddress(bytes32 _tokenName) public returns(address) {
      return tokens[_tokenName];
    }

       /**
    * @notice Get a Hydro Securities issuer contract deployed address   
    * @param  _tokenName The name of the token contract set to be deployed
    * @return the address of the issuer contract corresponding to that name
    */
    function getSecuritiesIssuerAddress(bytes32 _tokenName) public returns(address) {
      return issuers[_tokenName];
    }

       /**
    * @notice Get a Hydro Securities escrow contract deployed address
    * @param  _tokenName The name of the token contract set to be deployed
    * @return the address of the escrow contract corresponding to that name
    */
    function getSecuritiesEscrowAddress(bytes32 _tokenName) public returns(address) {
      return escrows[_tokenName];
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
      // check if token to be deployed already exists
      if ( tokens[_tokenName] != address(0) ) {
        // token exists, check if is alive
        HSTIssuer _issuer = HSTIssuer(tokens[_tokenName]);
      }
      tokens[_tokenName]  = deployToken(_tokenName, _description, _symbol, _decimals);
      issuers[_tokenName] = deployIssuer(_tokenName);
      escrows[_tokenName] = deployEscrow(_tokenName);
      emit SecuritiesDeployFinished(_tokenName);
    }

    /**
    * @notice Deploy a Hydro Securities Token contract
    * @param _tokenName         Name of the token to be issued
    * @param _decimals     Number of decimals of the smallest unit
    * @param _symbol       An identifier to designate the token to be issued
    * @param _totalSupply  Total number of tokens to mint in all stages
    */
    function deployToken(bytes32 _tokenName, string memory _description, string memory _symbol, uint8 _decimals) public onlySnowflakeOwner returns(address) {
      HydroSecuritiesToken _token = new HydroSecuritiesToken(_tokenName, _description, _symbol, _decimals);
      address _tokenAddress = address(_token);
      emit ContractDeployed(_tokenName, "TOKEN", _tokenAddress);
      return _tokenAddress;
    }

    /**
    * @notice Deploy a Hydro Securities Issuer contract   
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deployIssuer(bytes32 _tokenName, string memory _description, string memory _symbol, uint8 _decimals) public onlySnowflakeOwner returns(address) {
      HSTIssuer _issuer = new HSTIssuer(1, _tokenName, _description, _symbol, _decimals);
      address _issuerAddress = address(_issuer);
      emit ContractDeployed(_tokenName, "ISSUER", _issuerAddress);
      return _issuerAddress;
    }

    /**
    * @notice Deploy a Hydro Securities Escrow contract
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function deployEscrow(bytes32 _tokenName) public onlySnowflakeOwner returns(address) {
      //HSTEscrow _escrow = new HSTEscrow();
      //address _escrowAddress = address(_escrow);
      //emit ContractDeployed(_tokenName, "ESCROW", _escrowAddress);
      return address(0x0); //_escrowAddress;
    }

}
