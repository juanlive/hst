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

    struct Symbol {
      uint256 id;
      bool symbolExists;
    }

    uint256 public lastId = 0;

    IdentityRegistryInterface public IdentityRegistry;

    // Token name => Token data structure
    mapping(bytes32 => Token) public tokens;

    // Token symbol => ID data structure
    mapping(bytes32 => Symbol) public symbols;


    event TokenAppointedToRegistry(
      bytes32 _tokenName,
      bytes32 _tokenSymbol,
      address _tokenAddress,
      uint256 _id
    );

    event TokenAlreadyExists(
      bytes32 _tokenName,
      string _description
    );

    event SymbolAlreadyExists(
      bytes32 _tokenSymbol,
      string _description
    );

    constructor(address _identityRegistryAddress) public {
      IdentityRegistry = IdentityRegistryInterface(_identityRegistryAddress);
    }

 /**
    * @notice Get a Hydro Securities Token symbol
    * @param  _tokenName The name of the Token
    * @return the symbol of the Token corresponding to that name
    */
    function getSecuritiesTokenSymbol(bytes32 _tokenName) public view returns(bytes32) {
      return tokens[_tokenName].tokenSymbol;
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
    function getSecuritiesTokenDescription(bytes32 _tokenName) public view returns(string memory) {
      return tokens[_tokenName].tokenDescription;
    }

 /**
    * @notice Get a Hydro Securities token decimals
    * @param  _tokenName The name of the token
    * @return the number of decimals for the token corresponding to that name
    */
    function getSecuritiesTokenDecimal(bytes32 _tokenName) public view returns(uint8) {
      return tokens[_tokenName].tokenDecimals;
    }

    /**
    * @notice Appoint a new Token to the registry if token exists
    * @param  _tokenName The name of the token contract set to be deployed
    */
    function appointToken(
      bytes32 _tokenName,
      bytes32 _tokenSymbol,
      address _tokenAddress,
      string memory _tokenDescription,
      uint8 _tokenDecimals)
    public returns(bool) {

      if ( tokens[_tokenName].tokenExists ) {
        HSToken _token = HSToken(tokens[_tokenName].tokenAddress);
        if ( _token.isTokenAlive() ) {
          emit TokenAlreadyExists(_tokenName, "Token already exists and it is alive");
          return false;
        }
        if ( symbols[_tokenSymbol].symbolExists ) {
          emit SymbolAlreadyExists(_tokenSymbol, "Symnbol already exists");
          return false;
        }
      }

      uint256 _lastID; // Unique id for Tokens
      _lastID++;

      tokens[_tokenName].id = _lastID;
      tokens[_tokenName].tokenSymbol = _tokenSymbol;
      tokens[_tokenName].tokenAddress = address(_tokenAddress);
      tokens[_tokenName].ownerEIN = IdentityRegistry.getEIN(msg.sender);
      tokens[_tokenName].tokenDescription = _tokenDescription;
      tokens[_tokenName].tokenDecimals = _tokenDecimals;
      tokens[_tokenName].tokenExists = true;

      symbols[_tokenSymbol].id = _lastID;
      symbols[_tokenSymbol].symbolExists = true;

      emit TokenAppointedToRegistry(_tokenName, _tokenSymbol, address(_tokenAddress), _lastID);

      return true;
    }

}
