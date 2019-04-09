pragma solidity ^0.5.0;

import './components/SnowflakeOwnable.sol';
import './components/TokenWithDates.sol';
import './interfaces/HydroInterface.sol';
import './interfaces/ApproverInterface.sol';
import './interfaces/IdentityRegistryInterface.sol';
import './interfaces/SnowflakeViaInterface.sol';
import './zeppelin/math/SafeMath.sol';
import './zeppelin/ownership/Ownable.sol';

// Rinkeby testnet addresses
// HydroToken: 0x4959c7f62051d6b2ed6eaed3aaee1f961b145f20
// IdentityRegistry: 0xa7ba71305be9b2dfead947dc0e5730ba2abd28ea

// TODO
//
// A global Registry with data of all Securities issued, to check for repeated ids or symbols
//
// Feature #11: Participant functions -> send and receive token
// Feature #15: Carried interest ?
// Feature #16: Interest payout ?
// Feature #17: Dividend payout ?


/**
 * @title HSTIssuer
 * @notice The Hydro Security Token is a system to allow people to create their own Security Tokens, 
 *         related to their Snowflake identities and attached to external KYC, AML and other rules.
 * @author Juan Livingston <juanlivingston@gmail.com>
 */

contract HSTIssuer is 
    SnowflakeOwnable, Ownable {

    using SafeMath for uint256;
    
    enum Stage {
        SETUP, PRELAUNCH, ACTIVE, FINALIZED
    }

    // For date analysis
    struct Batch {
        uint initial; // Initial quantity received in a batch. Not modified in the future
        uint quantity; // Current quantity of tokens in a batch.
        uint age; // Birthday of the batch (timestamp)
    }

	// Main parameters
	uint256 id;
	string name;
	string description;
	string symbol;
    uint8 decimals;
	uint256 hydroPrice;
    uint256 ethPrice;
	uint256 beginningDate;
    uint256 lockEnds; // Date of end of locking period
	uint256 endDate;
    uint256 einOwner; // Instead of using the address we use EIN for the owner of the security
    uint256 maxSupply;
    uint256 escrowLimitPeriod;

	// STO types / flags
    bool LIMITED_OWNERSHIP;
    bool IS_LOCKED; // Locked token transfers
    bool PERIOD_LOCKED; // Locked period active or inactive
	bool PERC_OWNERSHIP_TYPE; // is ownership percentage limited type
    bool HYDRO_AMOUNT_TYPE; // is Hydro amount limited
    bool ETH_AMOUNT_TYPE; // is Ether amount limited
    bool HYDRO_ALLOWED; // Is Hydro allowed to purchase
    bool ETH_ALLOWED; // Is Ether allowed for purchase
    bool KYC_WHITELIST_RESTRICTED;
    bool AML_WHITELIST_RESTRICTED;

    // STO parameters
    uint256 percAllowedTokens; // considered if PERC_OWNERSHIP_TYPE
    uint256 hydroAllowed; // considered if HYDRO_AMOUNT_TYPE
    uint256 ethAllowed; // considered if ETH_AMOUNT_TYPE
    uint256 lockPeriod; // in days
    uint256 minInvestors;
    uint256 maxInvestors;

    // State Memory
    Stage stage; // SETUP, PRELAUNCH, ACTIVE, FINALIZED
    bool legalApproved;
    uint256 issuedTokens;
    uint256 ownedTokens;
    uint256 burnedTokens;
    uint256 hydroReceived;
    uint256 ethReceived;
    uint256 hydrosReleased; // Quantity of Hydros released by owner
    uint256 ethersReleased; // idem form Ethers

 	// Links to Modules
 	address HSToken;
	address RegistryRules;

	// Links to Registries
    address[5] KYCResolverArray;
    address[5] AMLResolverArray;
    address[5] LegalResolverArray;
    mapping(address => uint8) KYCResolver;
    mapping(address => uint8) AMLResolver;
    mapping(address => uint8) LegalResolver;
    uint8 KYCResolverQ;
    uint8 AMLResolverQ;
    uint8 LegalResolverQ;

    address InterestSolver;

    // Mappings
    mapping(uint256 => bool) public whiteList;
    mapping(uint256 => bool) public blackList;
    mapping(uint256 => bool) public freezed;

    mapping(address => uint256) public balance;

    // For date analysis and paying interests
    mapping(address => uint) public maxIndex; // Index of last batch: points to the next one
    mapping(address => uint) public minIndex; // Index of first batch
    mapping(address => mapping(uint => Batch)) public batches; // Batches with quantities and ages

    // Escrow contract's address => security number
    mapping(address => uint256) public escrowContracts;
    address[] public escrowContractsArray;


    // Declaring interfaces
    IdentityRegistryInterface public identityRegistry;
    HydroInterface public hydroToken;
    SnowflakeViaInterface public snowflakeVia;
    TokenWithDates private tokenWithDates;

    event HydroSTCreated(
        uint256 indexed id, 
        string name,
        string symbol,
        uint8 decimals,
        uint256 einOwner
        );

    event Sell(address indexed _owner, uint256 _amount);

    // Feature #9 & #10
    modifier isUnlocked() {
        require(!IS_LOCKED, "Token locked");
        if (PERIOD_LOCKED) require (now > lockEnds, "Locked period active");
        _;
    }

    modifier isUnfreezed(address _from, uint256 _einId) {
        require(!freezed[_einId] , "Target EIN is freezed");
        require(!freezed[identityRegistry.getEIN(_from)], "Source EIN is freezed");
        _;
    }

    modifier onlyAtPreLaunch() {
        require(stage == Stage.PRELAUNCH, "Not in Prelaunch stage");
    	_;
    }

    modifier onlyActive() {
        require(stage == Stage.ACTIVE, "Not active");
        _;
    }

    modifier onlyAdmin() {
        // Check if EIN of sender is the same as einOwner
        require(identityRegistry.getEIN(msg.sender) == einOwner, "Only for admins");
        _;
    }

    modifier escrowReleased() {
        require(escrowLimitPeriod < now, "Escrow limit period is still active");
        require(legalApproved, "Legal conditions are not met");
        _;
    }

    constructor(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _symbol,
        uint8 _decimals,
        uint256 _hydroPrice,
        uint256 _ethPrice,
        uint256 _beginningDate,
        uint256 _lockEnds, // Date of end of locking period
        uint256 _endDate,
        uint256 _maxSupply,
        uint256 _escrowLimitPeriod,

        // STO types / flags
        bool _LIMITED_OWNERSHIP,
        bool _IS_LOCKED,
        bool _PERIOD_LOCKED, 
        bool _PERC_OWNERSHIP_TYPE,
        bool _HYDRO_AMOUNT_TYPE, 
        bool _ETH_AMOUNT_TYPE, 
        bool _HYDRO_ALLOWED, 
        bool _ETH_ALLOWED,
        bool _KYC_WHITELIST_RESTRICTED,
        bool _AML_WHITELIST_RESTRICTED,

        // STO parameters
        uint256 _percAllowedTokens, // considered if PERC_OWNERSHIP_TYPE
        uint256 _hydroAllowed, // considered if HYDRO_AMOUNT_TYPE
        uint256 _ethAllowed, // considered if ETH_AMOUNT_TYPE
        uint256 _lockPeriod, // in days
        uint256 _minInvestors,
        uint256 _maxInvestors,
        address _owner) public {

        id = _id; 
        name = _name;
        description = _description;
        symbol = _symbol;
        decimals = _decimals;
        hydroPrice = _hydroPrice;
        ethPrice = _ethPrice;
        beginningDate = _beginningDate;
        lockEnds = _lockEnds;
        endDate = _endDate;
        maxSupply = _maxSupply;
        escrowLimitPeriod = _escrowLimitPeriod;

        // STO types / flags
        LIMITED_OWNERSHIP = _LIMITED_OWNERSHIP;
        IS_LOCKED = _IS_LOCKED;
        PERIOD_LOCKED = _PERIOD_LOCKED;
        PERC_OWNERSHIP_TYPE = _PERC_OWNERSHIP_TYPE;
        HYDRO_AMOUNT_TYPE = _HYDRO_AMOUNT_TYPE;
        ETH_AMOUNT_TYPE = _ETH_AMOUNT_TYPE; 
        HYDRO_ALLOWED = _HYDRO_ALLOWED; 
        ETH_ALLOWED = _ETH_ALLOWED; 
        KYC_WHITELIST_RESTRICTED = _KYC_WHITELIST_RESTRICTED;
        AML_WHITELIST_RESTRICTED = _AML_WHITELIST_RESTRICTED;

        // STO parameters
        percAllowedTokens = _percAllowedTokens; 
        hydroAllowed = _hydroAllowed; 
        ethAllowed = _ethAllowed; 
        lockPeriod = _lockPeriod; 
        minInvestors = _minInvestors;
        maxInvestors = _maxInvestors;

        // State Memory
        stage = Stage.SETUP;

        // Links to Modules
        HSToken = address(0x0);
        RegistryRules = address(0x0);
        InterestSolver = address(0x0);

        hydroToken = HydroInterface(0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20);
        identityRegistry = IdentityRegistryInterface(0xa7ba71305bE9b2DFEad947dc0E5730BA2ABd28EA);

        if (_owner == address(0x0)) _owner = msg.sender; else _owner = _owner;
        einOwner = identityRegistry.getEIN(_owner);

        emit HydroSTCreated(id, name, symbol, decimals, einOwner);
    }

    // Feature #10: ADMIN FUNCTIONS

    // Feature #9
    function setLockupPeriod(uint256 _lockEnds) onlyAdmin public {
        if (_lockEnds == 0) {
            PERIOD_LOCKED == false;
            }
        PERIOD_LOCKED = true;
        lockEnds = _lockEnds;
    }

    function lock() onlyAdmin public {
        IS_LOCKED = true;
    }

    function unLock() onlyAdmin public {
        IS_LOCKED = false;
    }

    function addWhitelist(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          whiteList[_einList[i]] == true;
        }
    }

    function addBlackList(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          blackList[_einList[i]] == true;
        }
    }

    function removeWhitelist(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          whiteList[_einList[i]] == false;
        }

    }

    function removeBlacklist(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          blackList[_einList[i]] == false;
        }
    }

    function freeze(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          freezed[_einList[i]] == true;
        }
    }

    function unFreeze(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          freezed[_einList[i]] == false;
        }
    }


    // Only at Prelaunch functions: adding and removing resolvers

    // Feature #3
    function addKYCResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(KYCResolver[_address] == 0, "Resolver already exists");
        require(KYCResolverQ <= 5, "No more resolvers allowed");
        identityRegistry.addResolver(_address);
        KYCResolverQ ++;
        KYCResolver[_address] = KYCResolverQ;
        KYCResolverArray[KYCResolverQ-1] = _address;
    }

    function removeKYCResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(KYCResolver[_address] != 0, "Resolver does not exist");
        uint8 _number = KYCResolver[_address];
        if (KYCResolverArray.length > _number) {
            for (uint8 i = _number; i < KYCResolverArray.length; i++) {
                KYCResolverArray[i-1] = KYCResolverArray[i];
            }
        }
        KYCResolverArray[KYCResolverQ - 1] = address(0x0);
        KYCResolverQ --;
        KYCResolver[_address] = 0;
        identityRegistry.removeResolver(_address); 
    }
    function addAMLResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(AMLResolver[_address] == 0, "Resolver already exists");
        require(AMLResolverQ <= 5, "No more resolvers allowed");
        identityRegistry.addResolver(_address);
        AMLResolverQ ++;
        AMLResolver[_address] = AMLResolverQ;
        AMLResolverArray[AMLResolverQ-1] = _address;
    }

    function removeAMLResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(AMLResolver[_address] != 0, "Resolver does not exist");
        uint8 _number = AMLResolver[_address];
        if (AMLResolverArray.length > _number) {
            for (uint8 i = _number; i < AMLResolverArray.length; i++) {
                AMLResolverArray[i-1] = AMLResolverArray[i];
            }
        }
        AMLResolverArray[AMLResolverQ - 1] = address(0x0);
        AMLResolverQ --;
        AMLResolver[_address] = 0;
        identityRegistry.removeResolver(_address); 
    }
        function addLegalResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(LegalResolver[_address] == 0, "Resolver already exists");
        require(LegalResolverQ <= 5, "No more resolvers allowed");
        identityRegistry.addResolver(_address);
        LegalResolverQ ++;
        LegalResolver[_address] = LegalResolverQ;
        LegalResolverArray[LegalResolverQ-1] = _address;
    }

    function removeLegalResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(LegalResolver[_address] != 0, "Resolver does not exist");
        uint8 _number = LegalResolver[_address];
        if (LegalResolverArray.length > _number) {
            for (uint8 i = _number; i < LegalResolverArray.length; i++) {
                LegalResolverArray[i-1] = LegalResolverArray[i];
            }
        }
        LegalResolverArray[LegalResolverQ - 1] = address(0x0);
        LegalResolverQ --;
        LegalResolver[_address] = 0;
        identityRegistry.removeResolver(_address); 
    }




    // Release gains. Only after escrow is released

    // Retrieve tokens and ethers
    function releaseHydroTokens() onlyAdmin escrowReleased public {
        uint256 thisBalance = hydroToken.balanceOf(address(this));
        hydrosReleased = hydrosReleased + thisBalance;
        hydroToken.transfer(owner, thisBalance);
    }

    function releaseEthers() onlyAdmin escrowReleased public {
        ethersReleased = ethersReleased + this.balance;
        owner.send(this.balance);
    }




    // PUBLIC FUNCTIONS FOR INVESTORS -----------------------------------------------------------------


    function buyTokens(string memory _coin, uint256 _amount) onlyActive
        public payable returns(bool) {

        uint256 total;
        uint256 _ein = identityRegistry.getEIN(msg.sender);

        require(stage == Stage.ACTIVE, "Current stage is not active");

        // CHECKINGS (to be exported as  a contract)
        // Coin allowance
        if (_coin == "HYDRO") require (HYDRO_ALLOWED, "Hydro is not allowed");
        if (_coin == "ETH") require (ETH_ALLOWED, "Ether is not allowed");
        // Check for limits
        if (HYDRO_AMOUNT_TYPE && _coin == "HYDRO") {
            require(hydroReceived.add(_amount) <= hydroAllowed, "Hydro amount exceeded");
        }
        if (ETH_AMOUNT_TYPE && _coin == "ETH") {
            require((ethReceived + msg.value) <= ethAllowed, "Ether amount exceeded");
        }
        // Check for whitelists
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(_ein, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(_ein, _amount);
        // Calculate total
        if (_coin == "HYDRO") {
            total = _amount.mul(hydroPrice);
            hydroReceived = hydroReceived.add(_amount);      
        }

        if (_coin == "ETH") {
            total = msg.value.mul(ethPrice);
            ethReceived = ethReceived + msg.value;
        }
        // Check for ownership percentage 
        if (PERC_OWNERSHIP_TYPE) {
            require ((issuedTokens.add(total) / ownedTokens) < percAllowedTokens, 
                "Perc ownership exceeded");
        }
        // Transfer Hydrotokens
        if (_coin == "HYDRO") {
            require(hydroToken.transferFrom(msg.sender, address(this), _amount), 
                "Hydro transfer was nos possible");
        }

        // Sell
        _doSell(msg.sender, total);
        emit Sell(msg.sender, total);
        return true;
    }


    function claimInterests() 
        public returns(bool) {
        //return(interestSolver(msg.sender));
        return true;
    }



    // Token ERC-20 wrapper -----------------------------------------------------------

    // Feature #11
    function transfer(address _to, uint256 _amount) 
        isUnlocked isUnfreezed(msg.sender, _to) 
        public returns(bool) {
        
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(_to, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(_to, _amount);

        tokenWithDates.updateBatches(msg.sender, _to, _amount);

        return(hydroToken.transfer(_to, _amount));
    }

    // Feature #11
    function transferFrom(address _from, address _to, uint256 _amount) 
        isUnlocked isUnfreezed(_from, _to) 
        public returns(bool) {
        
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(_to, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(_to, _amount);

        tokenWithDates.updateBatches(_from, _to, _amount);

        return(hydroToken.transferFrom(_from, _to, _amount));
    }




    // PUBLIC GETTERS ----------------------------------------------------------------

    function isLocked() public returns(bool) {
        return IS_LOCKED;
    }




    // INTERNAL FUNCTIONS ----------------------------------------------------------

     function _doSell(address _to, uint256 _amount) private {
        issuedTokens = issuedTokens + _amount;
        ownedTokens = ownedTokens + _amount;
        balance[_to].add(_amount);
    }


    // Permissions checking

    // Feature #8
    function _checkKYCWhitelist(uint256 _to, uint256 _amount) private {
        for (uint8 i = 1; i <= KYCResolverQ; i++) {
            ApproverInterface approver = new ApproverInterface(KYCResolver[i]);
            require(approver.isApproved(_to, _amount));
        }
    }
    function _checkAMLWhitelist(uint256 _to, uint256 _amount) private {
        for (uint8 i = 1; i <= AMLResolverQ; i++) {
            ApproverInterface approver = new ApproverInterface(AMLResolver[i]);
            require(approver.isApproved(_to, _amount));
        }
    }
    function _checkLegalWhitelist(uint256 _to, uint256 _amount) private {
        for (uint8 i = 1; i <= LegalResolverQ; i++) {
            ApproverInterface approver = new ApproverInterface(LegalResolver[i]);
            require(approver.isApproved(_to, _amount));
        }
    }

}
