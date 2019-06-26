pragma solidity ^0.5.0;

import './HSToken.sol';
import './interfaces/IdentityRegistryInterface.sol';

// TO DO

// check if token exists, then check if it is active
// allow new deployment if any of both is false, if both are true reject deployment

// add mainnet addresses
// add a parameter to choose deployment network

/**
 * @title HSTokenRegistry
 * @notice Perform deployment of contracts for the issuance of Hydro Securities
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTokenRegistry {

    struct Token {
      uint256 id;
      bytes32 tokenSymbol;
      address tokenAddress;
      uint256 ownerEIN;
      string tokenDescription;
      uint8 tokenDecimals;
      bool tokenExists;
    }

    uint256 public lastId = 0;

    // Token name => Token data structure
    mapping(bytes32 => Token) public tokens;

    // Token symbol => Token name
    mapping(bytes32 => bytes32) public symbols;


    // constructor() public {
    // }

 /**
    * @notice Get a Hydro Securities Token symbol
    * @param  _tokenName The name of the Token
    * @return the symbol of the Token corresponding to that name
    */
    function getSecuritiesTokenSymbol(bytes32 _tokenName) public view returns(bytes32) {
      return tokens[_tokenName].symbol;
    }

   /**
    * @notice Get a Hydro Securities Token contract deployed address
    * @param  _tokenName The name of the token
    * @return the address of the token contract corresponding to that name
    */
    function getSecuritiesTokenAddress(bytes32 _tokenName) public view returns(address) {
      return tokens[_tokenName].tokenAddress;
    }

 /**
    * @notice Get a Hydro Securities token owner EIN
    * @param  _tokenName The name of the token
    * @return the owner EIN of the token contract corresponding to that name
    */
    function getSecuritiesTokenOwnerEIN(bytes32 _tokenName) public view returns(uint256) {
      return tokens[_tokenName].ownerEIN;
    }

 /**
    * @notice Get a Hydro Securities token description
    * @param  _tokenName The name of the token
    * @return the description for the token corresponding to that name
    */
    function getSecuritiesTokenDescription(bytes32 _tokenName) public view returns(memory string) {
      return tokens[_tokenName].description;
    }

 /**
    * @notice Get a Hydro Securities token decimals
    * @param  _tokenName The name of the token
    * @return the number of decimals for the token corresponding to that name
    */
    function getSecuritiesTokenDecimal(bytes32 _tokenName) public view returns(uint8) {
      return tokens[_tokenName].decimals;
    }

    /**
    * @notice Appoint a new Token to the registry if token exists
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function appointToken(
      bytes32 _tokenName,
      bytes32 _tokenSymbol,
      address _tokenAddress,
      uint256 _ownerEIN,
      string memory _tokenDescription;
      uint8 _tokenDecimals)
    public returns(bool) {

      if ( tokens[_tokenName].exists ) {
        HSToken _token = HSToken(tokens[_tokenName].tokenAddress);
        if ( _token.isTokenAlive() ) {
          emit TokenAlreadyExists(_tokenName, "Token exists and it is alive");
          return false;
        }
      }

      last_id++; // Prepare unique id

      tokens[_tokenName].id = last_id;
      tokens[_tokenName].tokenSymbol = _tokenSymbol;
      tokens[_tokenName].tokenAddress = address(_token);
      tokens[_tokenName].ownerEIN = IdentityRegistry.getEIN(msg.sender);
      tokens[_tokenName].tokenDescription = _tokenDescription;
      tokens[_tokenName].tokenDecimals = _tokenDecimals;
      tokens[_tokenName].exists = true;

      emit TokenAppointedToRegistry(_tokenName, address(_token));

      return true;
    }

}
