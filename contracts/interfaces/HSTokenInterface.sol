pragma solidity ^0.5.0;

interface HSTokenInterface  {
  
    bool public exists;
	// Main parameters
	uint256 public id;
	bytes32 public name;
	string public description;
	string public symbol;
    uint8 public decimals;
    address payable public Owner;
    uint256 einOwner;

    // State Memory
    bool legalApproved;
    uint256 issuedTokens;
    uint256 public ownedTokens;
    uint256 public burnedTokens;
    uint256 public hydroReceived;
    uint256 public ethReceived;
    uint256 hydrosReleased; // Quantity of Hydros released by owner
    uint256 ethersReleased; // idem form Ethers

 	// Links to Modules
	address RegistryRules;

	// Links to Registries
    //address[5] public KYCResolverArray;
    //address[5] public AMLResolverArray;
    //address[5] public LegalResolverArray;
    uint8 KYCResolverQ;
    uint8 AMLResolverQ;
    uint8 LegalResolverQ;

    address InterestSolver;

    // Mappings
    mapping(uint256 => bool) public whiteList;
    mapping(uint256 => bool) public blackList;
    mapping(uint256 => bool) public freezed;

    mapping(address => uint256) public balance;
}
