pragma solidity ^0.5.0;


//import './components/SnowflakeOwnable.sol';
//import './components/TokenWithDates.sol';
import './interfaces/HydroInterface.sol';
import './interfaces/ApproverInterface.sol';
import './interfaces/IdentityRegistryInterface.sol';
//import './interfaces/SnowflakeViaInterface.sol';
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
 * @title HSToken
 * @notice The Hydro Security Token is a system to allow people to create their own Security Tokens, 
 *         related to their Snowflake identities and attached to external KYC, AML and other rules.
 * @author Juan Livingston <juanlivingston@gmail.com>
 */


  /**
  * @notice We use contracts to store main variables, because Solidity can not habdle so many individual variables
  */

contract MAIN_PARAMS {
    bool MAIN_PARAMS;

    uint256 hydroPrice;
    uint256 ethPrice;
    uint256 beginningDate;
    uint256 lockEnds; // Date of end of locking period
    uint256 endDate;
    uint256 maxSupply;
    uint256 escrowLimitPeriod;
}

contract STO_FLAGS {
    bool STO_FLAGS;

    bool LIMITED_OWNERSHIP; 
    bool IS_LOCKED; // Locked token transfers
    bool PERIOD_LOCKED;  // Locked period active or inactive
    bool PERC_OWNERSHIP_TYPE; // is ownership percentage limited type
    bool HYDRO_AMOUNT_TYPE; // is Hydro amount limited
    bool ETH_AMOUNT_TYPE; // is Ether amount limited
    bool HYDRO_ALLOWED; // Is Hydro allowed to purchase
    bool ETH_ALLOWED; // Is Ether allowed for purchase
    bool KYC_WHITELIST_RESTRICTED; 
    bool AML_WHITELIST_RESTRICTED;
}

contract STO_PARAMS {
    bool STO_PARAMS;

    uint256 percAllowedTokens; // considered if PERC_OWNERSHIP_TYPE
    uint256 hydroAllowed; // considered if HYDRO_AMOUNT_TYPE
    uint256 ethAllowed; // considered if ETH_AMOUNT_TYPE
    uint256 lockPeriod; // in days
    uint256 minInvestors;
    uint256 maxInvestors;
}

contract HSToken is MAIN_PARAMS, STO_FLAGS, STO_PARAMS {

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

    bool public exists; // Flag to deactivate it
    uint256 public registerDate; // Date of creation of token
	// Main parameters
	uint256 public id; // Unique HSToken id
	bytes32 public name;
	string public description;
	string public symbol;
    uint8 public decimals;
    address payable public Owner;
    uint256 einOwner;

    // State Memory
    Stage public stage; // SETUP, PRELAUNCH, ACTIVE, FINALIZED
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
    address[5] public KYCResolverArray;
    address[5] public AMLResolverArray;
    address[5] public LegalResolverArray;
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
    //mapping(address => uint256) public escrowContracts;
    // address[] public escrowContractsArray;

    // Declaring interfaces
    IdentityRegistryInterface public identityRegistry;
    HydroInterface public hydroToken;
    // SnowflakeViaInterface public snowflakeVia;
    // TokenWithDates private tokenWithDates;


    event HydroSTCreated(
        uint256 indexed id, 
        bytes32 name,
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

    modifier isUnfreezed(address _from, address _to) {
        require(!freezed[identityRegistry.getEIN(_to)] , "Target EIN is freezed");
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

    modifier requireSetup() {
        require(stage == Stage.SETUP, "Stage is not setup");
        require(isSetupTime(), "Setup time has expired");
        _;
    }

    modifier requirePrelaunch() {
        require(stage == Stage.PRELAUNCH, "Stage is not prelaunch");
        _;
    }

    constructor(
        uint256 _id,
        bytes32 _name,
        string memory _description,
        string memory _symbol,
        uint8 _decimals
        ) public {

        id = _id; 
        name = _name;
        description = _description;
        symbol = _symbol;
        decimals = _decimals;

        exists = true;
        registerDate = now;

        // State Memory
        stage = Stage.SETUP;

        // Links to Modules
        RegistryRules = 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20;
        //InterestSolver = address(0x0);

        hydroToken = HydroInterface(0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20);
        identityRegistry = IdentityRegistryInterface(0xa7ba71305bE9b2DFEad947dc0E5730BA2ABd28EA);

        Owner = msg.sender;
        einOwner = 234; // identityRegistry.getEIN(Owner);

        emit HydroSTCreated(id, name, symbol, decimals, einOwner);
    }


    // ADMIN SETUP FUNCTIONS


    function set_MAIN_PARAMS(
        uint256 _hydroPrice,
        uint256 _ethPrice,
        uint256 _beginningDate,
        uint256 _lockEnds,
        uint256 _endDate,
        uint256 _maxSupply,
        uint256 _escrowLimitPeriod
    ) onlyAdmin requireSetup public  {
        // Validations
        require(
            (_hydroPrice > 0 || _ethPrice > 0) &&
            (_beginningDate == 0 || _beginningDate > now) &&
            (_lockEnds > _beginningDate && _lockEnds > now) &&
            _endDate > _lockEnds &&
            _maxSupply > 10000 &&
            _escrowLimitPeriod > (10 * 24 * 60 * 60),
            "Incorrect input data"
            );
        // Load values
        hydroPrice = _hydroPrice;
        ethPrice = _ethPrice;
        beginningDate = _beginningDate;
        lockEnds = _lockEnds; // Date of end of locking period
        endDate = _endDate;
        maxSupply = _maxSupply;
        escrowLimitPeriod = _escrowLimitPeriod;
        // Set flag
        MAIN_PARAMS = true;
    }


    function set_STO_FLAGS(
        bool _LIMITED_OWNERSHIP, 
        bool _IS_LOCKED,
        bool _PERIOD_LOCKED,
        bool _PERC_OWNERSHIP_TYPE,
        bool _HYDRO_AMOUNT_TYPE,
        bool _ETH_AMOUNT_TYPE,
        bool _HYDRO_ALLOWED,
        bool _ETH_ALLOWED,
        bool _KYC_WHITELIST_RESTRICTED, 
        bool _AML_WHITELIST_RESTRICTED
    ) onlyAdmin requireSetup public {
        // Load values
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
        // Set flag
        STO_FLAGS = true;
    }

    function set_STO_PARAMS(
        uint256 _percAllowedTokens, 
        uint256 _hydroAllowed,
        uint256 _ethAllowed,
        uint256 _lockPeriod,
        uint256 _minInvestors,
        uint256 _maxInvestors
    ) onlyAdmin requireSetup public {
        require(STO_FLAGS, "STO_FLAGS has not been sat");

        percAllowedTokens = _percAllowedTokens; 
        hydroAllowed = _hydroAllowed;
        ethAllowed = _ethAllowed;
        lockPeriod = _lockPeriod;
        minInvestors = _minInvestors;
        maxInvestors = _maxInvestors;
        // Set flag
        STO_PARAMS = true;
    }


    function activatePrelaunch() onlyAdmin requireSetup public {
        require(MAIN_PARAMS, "MAIN_PARAMS not setted");
        require(STO_FLAGS, "STO_FLAGS not setted");
        require(STO_PARAMS, "STO_PARAMS not setted");

        if (beginningDate == 0) beginningDate = now;

        stage = Stage.PRELAUNCH;
    }




    // Feature #10: ADMIN FUNCTIONS


    // Feature #9
    function setLockupPeriod(uint256 _lockEnds) onlyAdmin public {
        if (_lockEnds == 0) {
            PERIOD_LOCKED = false;
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
          whiteList[_einList[i]] = true;
        }
    }

    function addBlackList(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          blackList[_einList[i]] = true;
        }
    }

    function removeWhitelist(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          whiteList[_einList[i]] = false;
        }

    }

    function removeBlacklist(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          blackList[_einList[i]] = false;
        }
    }

    function freeze(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          freezed[_einList[i]] = true;
        }
    }

    function unFreeze(uint256[] memory _einList) onlyAdmin public {
        for (uint i = 0; i < _einList.length; i++) {
          freezed[_einList[i]] = false;
        }
    }


    // Only at Prelaunch functions: adding and removing resolvers

    // Feature #3
    function addKYCResolver(address[] memory _address) onlyAdmin onlyAtPreLaunch public {
        //require(KYCResolverQ < 4, "There are already 5 resolvers for KYC");
        //require(_address.length == 1, "Only one address per time");
        //KYCResolverArray[KYCResolverQ] = _address[0];
        //KYCResolverQ ++;
        identityRegistry.addResolvers(_address);

    }

    function removeKYCResolver(address[] memory _address) onlyAdmin onlyAtPreLaunch public {
        identityRegistry.removeResolvers(_address); 
    }
    function addAMLResolver(address[] memory _address) onlyAdmin onlyAtPreLaunch public {
        identityRegistry.addResolvers(_address);

    }

    function removeAMLResolver(address[] memory _address) onlyAdmin onlyAtPreLaunch public {
        identityRegistry.removeResolvers(_address); 
    }
    function addLegalResolver(address[] memory _address) onlyAdmin onlyAtPreLaunch public {
        identityRegistry.addResolvers(_address);
    }

    function removeLegalResolver(address[] memory _address) onlyAdmin onlyAtPreLaunch public {
        identityRegistry.removeResolvers(_address);  
    }




    // Release gains. Only after escrow is released

    // Retrieve tokens and ethers
    function releaseHydroTokens() onlyAdmin escrowReleased public {
        uint256 thisBalance = hydroToken.balanceOf(address(this));
        hydrosReleased = hydrosReleased + thisBalance;
        require(hydroToken.transfer(Owner, thisBalance));
    }

    function releaseEthers() onlyAdmin escrowReleased public {
        ethersReleased = ethersReleased + address(this).balance;
        require(Owner.send(address(this).balance));
    }




    // PUBLIC FUNCTIONS FOR INVESTORS -----------------------------------------------------------------


    function buyTokens(string memory _coin, uint256 _amount) onlyActive
        public payable returns(bool) {

        uint256 total;
        uint256 _ein = identityRegistry.getEIN(msg.sender);
        bytes32 HYDRO = keccak256(abi.encode("HYDRO"));
        bytes32 ETH =  keccak256(abi.encode("ETH"));
        bytes32 coin = keccak256(abi.encode(_coin));

        require(stage == Stage.ACTIVE, "Current stage is not active");

        // CHECKINGS (to be exported as  a contract)
        // Coin allowance
        if (coin == HYDRO) require (HYDRO_ALLOWED, "Hydro is not allowed");
        if (coin == ETH) require (ETH_ALLOWED, "Ether is not allowed");
        // Check for limits
        if (HYDRO_AMOUNT_TYPE && coin == HYDRO) {
            require(hydroReceived.add(_amount) <= hydroAllowed, "Hydro amount exceeded");
        }
        if (ETH_AMOUNT_TYPE && coin == ETH) {
            require((ethReceived + msg.value) <= ethAllowed, "Ether amount exceeded");
        }
        // Check for whitelists
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(msg.sender, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(msg.sender, _amount);
        // Calculate total
        if (coin == HYDRO) {
            total = _amount.mul(hydroPrice);
            hydroReceived = hydroReceived.add(_amount);      
        }

        if (coin == ETH) {
            total = msg.value.mul(ethPrice);
            ethReceived = ethReceived + msg.value;
        }
        // Check for ownership percentage 
        if (PERC_OWNERSHIP_TYPE) {
            require ((issuedTokens.add(total) / ownedTokens) < percAllowedTokens, 
                "Perc ownership exceeded");
        }
        // Transfer Hydrotokens
        if (coin == HYDRO) {
            require(hydroToken.transferFrom(msg.sender, address(this), _amount), 
                "Hydro transfer was nos possible");
        }

        // Sell
        _doSell(msg.sender, total);
        emit Sell(msg.sender, total);
        return true;
    }


    function claimInterests() 
        public pure returns(bool) {
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

        // _updateBatches(msg.sender, _to, _amount);

        return true;
    }

    // Feature #11
    function transferFrom(address _from, address _to, uint256 _amount) 
        isUnlocked isUnfreezed(_from, _to) 
        public returns(bool) {
        
        if (KYC_WHITELIST_RESTRICTED) _checkKYCWhitelist(_to, _amount);
        if (AML_WHITELIST_RESTRICTED) _checkAMLWhitelist(_to, _amount);

        // _updateBatches(_from, _to, _amount);

        return true;;
    }




    // PUBLIC GETTERS ----------------------------------------------------------------

    function isLocked() public view returns(bool) {
        return IS_LOCKED;
    }

    function isAlive() public view returns(bool) {
        if (!exists) return false;
        if (stage != Stage.SETUP) return true;
        // If it is in the Stup stage, check that date has not been surpassed
        return isSetupTime();
    }

    function isSetupTime() internal view returns(bool) {
        // 15 days to complete setup
        return((now - registerDate) < (15 * 24 * 60 * 60));
    }


    // INTERNAL FUNCTIONS ----------------------------------------------------------

     function _doSell(address _to, uint256 _amount) private {
        issuedTokens = issuedTokens + _amount;
        ownedTokens = ownedTokens + _amount;
        balance[_to].add(_amount);
    }


    // Permissions checking

    // Feature #8
    function _checkKYCWhitelist(address _to, uint256 _amount) private view {
        uint256 einTo = identityRegistry.getEIN(_to);

        for (uint8 i = 1; i <= KYCResolverQ; i++) {
            //ApproverInterface approver = ApproverInterface(KYCResolverArray[i-1]);
            //require(approver.isApproved(einTo, _amount));
        }
    }
    function _checkAMLWhitelist(address _to, uint256 _amount) private view {
        uint256 einTo = identityRegistry.getEIN(_to);

        for (uint8 i = 1; i <= AMLResolverQ; i++) {
            //ApproverInterface approver = ApproverInterface(AMLResolverArray[i-1]);
            //require(approver.isApproved(einTo, _amount));
        }
    }
    function _checkLegalWhitelist(address _to, uint256 _amount) private view {
        uint256 einTo = identityRegistry.getEIN(_to);

        for (uint8 i = 1; i <= LegalResolverQ; i++) {
           // ApproverInterface approver = ApproverInterface(LegalResolverArray[i-1]);
            //require(approver.isApproved(einTo, _amount));
        }
    }

}
