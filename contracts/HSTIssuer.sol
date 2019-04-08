pragma solidity ^0.5.4;

import './components/SnowflakeOwnable.sol';
import './components/HSTEscrow.sol';
import './components/TokenWithDates.sol';
import './interfaces/HydroInterface.sol';
import './interfaces/IdentityRegistryInterface.sol';
import './interfaces/SnowflakeViaInterface.sol';
import './zeppelin/math/SafeMath.sol';
import './zeppelin/ownership/Ownable.sol';

// Rinkeby testnet addresses
// HydroToken: 0x4959c7f62051d6b2ed6eaed3aaee1f961b145f20
// IdentityRegistry: 0xa7ba71305be9b2dfead947dc0e5730ba2abd28ea
// Most recent HydroST deployed address:

// TODO
//
// A global Registry with data of all Securities issued, to check for repeated ids or symbols
//
// Feature #2: Define and implement HST rules (ongoing)
// Feature #10: Admin functions (ongoing)
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
    SnowflakeOwnable isOwner {

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
	bytes32 name;
	string description;
	string symbol;
	uint256 hydroPrice;
    uint256 etherPrice;
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
    address KYCResolver;
    address AMLResolver;
    address LegalResolver;
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


    event HydroSTCreated(
        uint256 indexed id, 
        string name,
        string symbol,
        uint8 decimals,
        bytes32 EINowner
        );

    event Sell(address indexed _owner, uint256 _amount);

    // Feature #9 & #10
    modifier isUnlocked() {
        require(!IS_LOCKED, "Token locked");
        if (PERIOD_LOCKED) require (now > lockEnds, "Locked period active");
        _;
    }

    modifier isUnfreezed(_from, _einId) {
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
        address _identityRegistryAddress, 
        address _HSToken,
        uint256 _lockPeriod,
        uint256 _minInvestors,
        uint256 _maxInvestors,
        uint256 _percForInvestors,
        bytes32 _name,
        string _description,
        uint256 _fee,
        address _feeReceiver,
        address _KYCResolver,
        bytes32 _KYCbytes,
        bool PERC_OWNERSHIP_TYPE,
        bool HYDRO_AMOUNT_TYPE,
        ) 
    public {
        require(_identityRegistryAddress != address(0), 'The identity registry address is required');
        require(_HSToken != address(0), 'You must setup the token rinkeby address');
        hydroToken = HydroInterface(_HSToken);
        identityRegistry = IdentityRegistryInterface(_identityRegistryAddress);

    }

    // Feature #10: ADMIN FUNCTIONS

    // Feature #9
    function setLockupPeriod(uint256 _lockEnds) public onlyAdmin {
        if (_lockEnds == 0) {
            PERIOD_LOCKED == false;
            }
        PERIOD_LOCKED = true;
        lockEnds = _lockEnds;
    }

    function lock() public onlyAdmin {
        IS_LOCKED = true;
    }

    function unLock() public onlyAdmin {
        IS_LOCKED = false;
    }

    function addWhitelist(uint256[] _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          whiteList[_einList[i]] == true;
        }
    }

    function addBlackList(uint256[] _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          blackList[_einList[i]] == true;
        }
    }

    function removeWhitelist(uint256[] _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          whiteList[_einList[i]] == false;
        }

    }

    function removeBlacklist(uint256[] _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          blackList[_einList[i]] == false;
        }
    }

    function freeze(uint256[] _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          freeze[_einList[i]] == true;
        }
    }

    function unFreeze(uint256[] _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          freeze[_einList[i]] == false;
        }
    }


    // Only at Prelaunch functions, to configure the token

    // Feature #3
    function addKYCApproval(address _address) public onlyAdmin onlyAtPreLaunch {
        interface = IdentityRegistryInterface(_address);
        interface.addResolver(address(this)); // See which function to call
        KYCresolver = _address;

    }

    // Feature #4
    function addAMLApproval(address _address) public onlyAdmin onlyAtPreLaunch {
        interface = IdentityRegistryInterface(_address);
        interface.addResolver(address(this)); // See which function to call
        AMLresolver = _address;
    }

    // Registry updaters
    function updateKYCResolver(address _resolver) public onlyAdmin onlyAtSetup {
        require(KYCResolver==0x0, "KYC Resolver is already set");
        KYCResolver = _resolver;
    }

    function updateAMLResolver(address _resolver) public onlyAdmin onlyAtSetup {
        require(AMLResolver==0x0, "AML Resolver is already set");
        AMLResolver = _resolver;
    }

    function updateLegalResolver(address _resolver) public onlyAdmin onlyAtSetup {
        require(LegalResolver==0x0, "Legal Resolver is already set");
        LegalResolver = _resolver;
    }


    // Only after escrow is released

    // Retrieve tokens and ethers
    function releaseHydroTokens() public onlyAdmin scrowReleased {
        uint256 memory balance = hydroToken.balanceOf(address(this));
        hydrosReleased = hydrosReleased + balance;
        hydrotoken.transfer(_owner, balance);
    }

    function releaseEthers() public onlyAdmin scrowReleased {
        ethersReleased = ethersRetrieved + this.balance;
        _owner.send(this.balance);
    }




    // PUBLIC FUNCTIONS FOR INVESTORS -----------------------------------------------------------------


    function buyTokens(string _coin, uint256 _amount) public payable return(bool) onlyActive {

        uint256 memory total;

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
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(msg.sender, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(msg.sender, _amount);
        // Calculate total
        if (_coin == "HYDRO") {
            total = _amount * hydroPrice;
            hydroReceived = hydroReceived + _amount;      
        }

        if (_coin == "ETH") {
            total = msg.value * ethPrice;
            ethReceived = ethReceived + msg.value;
        }
        // Check for ownership percentage 
        if (PERC_OWNERSHIP_TYPE) {
            require (((issuedTokens + total) / ownedTokens) < percAllowedTokens, 
                "Perc ownership exceeded");
        }
        // Transfer Hydrotokens
        if (_coin == "HYDRO") {
            require(hydroToken.transferFrom(msg.sender, address(this), _amount), 
                "Hydro transfer was nos possible");
        }

        // Sell
        _doSell(_to, total);
        emit Sell(_to, total);
        return true;
    }


    function claimInterests() public returns(bool) {
       return(interestSolver(msg.sender));
    }



    // Token ERC-20 wrapper ------------------------------------------------------

    // Feature #11
    function transfer(address _to, uint256 _amount) public returns(bool) 
        isUnlocked isUnfreezed(msg.sender, _to) {
        
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(_to, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(_to, _amount);

        tokenWithADate.updateBatches(msg.sender, _to, _amount);

        return(HydroToken.transfer(_to, _amount));
    }

    // Feature #11
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) 
        isUnlocked isUnfreezed(_from, _to) {
        
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(_to, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(_to, _amount);

        tokenWithADate.updateBatches(_from, _to, _amount);

        return(HydroToken.transferFrom(_from, _to, _amount));
    }




    // PUBLIC GETTERS ----------------------------------------------------------------

    function isLocked() public returns(bool) {
        return IS_LOCKED;
    }




    // INTERNAL FUNCTIONS ----------------------------------------------------------

     function _doSell(_to, _amount) private {
        issuedTokens = issuedTokens + _amount;
        ownedTokens = ownedTokens + _amount;
        balance[_to].add(_amount);
    }


    // Permissions checking

    // Feature #8
    function _checkKYCWhitelist(_to, _amount) private {
            KYC = new SnowflakeViaInterface(KYCresolver);
            require (KYC.snowflakeCall(KYCresolver, _to, _amount), "Not in KYC whitelist"); // Which function to call?
        }
    function _checkAMLWhitelist(_to, _amount) private {
            AML = new SnowflakeViaInterface(AMLresolver);  
            require (AML.snowflakeCall(KYCresolver, _to, _amount), "Not in AML whitelist"); // Which function to call?
    }

}
