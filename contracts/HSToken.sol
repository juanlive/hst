pragma solidity ^0.5.0;


//import './components/SnowflakeOwnable.sol';
//import './components/TokenWithDates.sol';
import './components/HSTServiceRegistry.sol';
import './interfaces/HydroInterface.sol';
import './interfaces/ResolverInterface.sol';
import './interfaces/IdentityRegistryInterface.sol';
//import './interfaces/SnowflakeViaInterface.sol';
import './zeppelin/math/SafeMath.sol';
import './zeppelin/ownership/Ownable.sol';


// For testing

// Rinkeby testnet addresses
// HydroToken: 0x4959c7f62051d6b2ed6eaed3aaee1f961b145f20
// IdentityRegistry: 0xa7ba71305be9b2dfead947dc0e5730ba2abd28ea

// TODO
//
// External pricer
//
// A global Registry with data of all Securities issued, to check for repeated ids or symbols
//
// Feature #15: Carried interest ?
// Feature #16: Interest payout ?
// Feature #17: Dividend payout ?


/**
 * @title HSToken
 * @notice The Hydro Security Token is a system to allow people to create their own Security Tokens, 
 *         related to their Snowflake identities and attached to external KYC, AML and other rules.
 * @author Juan Livingston <juanlivingston@gmail.com>
 */

interface Raindrop {
    function authenticate(address _sender, uint _value, uint _challenge, uint _partnerId) external;
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

/**
* @dev We use contracts to store main variables, because Solidity can not handle so many individual variables
*/

contract MAIN_PARAMS {
    bool public MAIN_PARAMS_ready;

    uint256 public hydroPrice;
    uint256 public ethPrice;
    uint256 public beginningDate;
    uint256 public lockEnds; // Date of end of locking period
    uint256 public endDate;
    uint256 public maxSupply;
    uint256 public escrowLimitPeriod;
}

contract STO_FLAGS {
    bool public STO_FLAGS_ready;

    bool public LIMITED_OWNERSHIP; 
    bool public IS_LOCKED; // Locked token transfers
    bool public PERIOD_LOCKED;  // Locked period active or inactive
    bool public PERC_OWNERSHIP_TYPE; // is ownership percentage limited type
    bool public HYDRO_AMOUNT_TYPE; // is Hydro amount limited
    bool public ETH_AMOUNT_TYPE; // is Ether amount limited
    bool public HYDRO_ALLOWED; // Is Hydro allowed to purchase
    bool public ETH_ALLOWED; // Is Ether allowed for purchase
    bool public KYC_RESTRICTED; 
    bool public AML_RESTRICTED;
    bool public WHITELIST_RESTRICTED;
    bool public BLACKLIST_RESTRICTED;
}

contract STO_PARAMS {
    bool public STO_PARAMS_ready;
    // @param percAllowedTokens Where 100% = 1 ether, 50% = 0.5 ether
    uint256 public percAllowedTokens; // considered if PERC_OWNERSHIP_TYPE
    uint256 public hydroAllowed; // considered if HYDRO_AMOUNT_TYPE
    uint256 public ethAllowed; // considered if ETH_AMOUNT_TYPE
    uint256 public lockPeriod; // in days
    uint256 public minInvestors;
    uint256 public maxInvestors;
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
        uint age; // Creation of the batch (timestamp)
    }

    struct Investor {
        bool exist;
        uint256 etherSent;
        uint256 hydroSent;
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
    uint256 public einOwner;

    // State Memory
    Stage public stage; // SETUP, PRELAUNCH, ACTIVE, FINALIZED
    bool legalApproved;
    uint256 public issuedTokens;
    uint256 public burnedTokens;
    uint256 public hydroReceived;
    uint256 public ethReceived;
    uint256 public investorsQuantity;
    uint256 hydrosReleased; // Quantity of Hydros released by owner
    uint256 ethersReleased; // idem form Ethers

 	// Links to Modules
	// address public RegistryRules;
    address public raindropAddress;

	// Links to Registries
    address[5] public KYCResolverArray;
    address[5] public AMLResolverArray;
    address[5] public LegalResolverArray;
    uint8 KYCResolverQ;
    uint8 AMLResolverQ;
    uint8 LegalResolverQ;

    // address InterestSolver;

    // Mappings
    mapping(uint256 => bool) public whiteList;
    mapping(uint256 => bool) public blackList;
    mapping(uint256 => bool) public freezed;

    mapping(address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowed;

    mapping(uint256 => Investor) public investors;

    // For date analysis and paying interests
    mapping(address => uint) public maxIndex; // Index of last batch: points to the next one
    mapping(address => uint) public minIndex; // Index of first batch
    mapping(address => mapping(uint => Batch)) public batches; // Batches with quantities and ages

    // Escrow contract's address => security number
    // mapping(address => uint256) public escrowContracts;
    // address[] public escrowContractsArray;

    // Declaring interfaces
    IdentityRegistryInterface public identityRegistry;
    HydroInterface public hydroToken;
    // HSTServiceRegistry public serviceRegistry;
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

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

    // Feature #9 & #10
    modifier isUnlocked() {
        require(!IS_LOCKED, "Token locked");
        if (PERIOD_LOCKED) require (now > lockEnds, "Locked period active");
        _;
    }

    modifier isUnfreezed(address _from, address _to) {
        require(!freezed[identityRegistry.getEIN(_to)], "Target EIN is freezed");
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

    modifier onlyAtSetup() {
        require(stage == Stage.SETUP, "Stage is not setup");
        require(isSetupTime(), "Setup time has expired");
        _;
    }

    modifier requirePrelaunch() {
        require(stage == Stage.PRELAUNCH, "Stage is not prelaunch");
        require(beginningDate == 0 || beginningDate > now, "Prelaunch time has passed");
        _;
    }

    constructor(
        uint256 _id,
        bytes32 _name,
        string memory _description,
        string memory _symbol,
        uint8 _decimals,
        address _HydroToken,
        address _IdentityRegistry
        // address _RaindropAddress
    ) 
        public 
    {

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
        // RegistryRules = 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20;
        // InterestSolver = address(0x0);

        hydroToken = HydroInterface(_HydroToken); // 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20
        identityRegistry = IdentityRegistryInterface(_IdentityRegistry); // 0xa7ba71305bE9b2DFEad947dc0E5730BA2ABd28EA
        // serviceRegistry = new HSTServiceRegistry();
        // raindropAddress = _RaindropAddress;

        Owner = msg.sender;
        einOwner = identityRegistry.getEIN(Owner);

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
    ) 
        onlyAdmin onlyAtSetup public  
    {
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
        MAIN_PARAMS_ready = true;

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
        bool _KYC_RESTRICTED, 
        bool _AML_RESTRICTED,
        bool _WHITELIST_RESTRICTED,
        bool _BLACKLIST_RESTRICTED
    ) 
        onlyAdmin onlyAtSetup public 
    {
        // Load values
        LIMITED_OWNERSHIP = _LIMITED_OWNERSHIP; 
        IS_LOCKED = _IS_LOCKED;
        PERIOD_LOCKED = _PERIOD_LOCKED;
        PERC_OWNERSHIP_TYPE = _PERC_OWNERSHIP_TYPE;
        HYDRO_AMOUNT_TYPE = _HYDRO_AMOUNT_TYPE;
        ETH_AMOUNT_TYPE = _ETH_AMOUNT_TYPE;
        HYDRO_ALLOWED = _HYDRO_ALLOWED;
        ETH_ALLOWED = _ETH_ALLOWED;
        KYC_RESTRICTED = _KYC_RESTRICTED; 
        AML_RESTRICTED = _AML_RESTRICTED;
        WHITELIST_RESTRICTED = _WHITELIST_RESTRICTED;
        BLACKLIST_RESTRICTED = _BLACKLIST_RESTRICTED;
        // Set flag
        STO_FLAGS_ready = true;
    }

    function set_STO_PARAMS(
        uint256 _percAllowedTokens, 
        uint256 _hydroAllowed,
        uint256 _ethAllowed,
        uint256 _lockPeriod,
        uint256 _minInvestors,
        uint256 _maxInvestors
    ) 
        onlyAdmin onlyAtSetup public 
    {
        require(STO_FLAGS_ready, "STO_FLAGS has not been sat");

        percAllowedTokens = _percAllowedTokens; 
        hydroAllowed = _hydroAllowed;
        ethAllowed = _ethAllowed;
        lockPeriod = _lockPeriod;
        minInvestors = _minInvestors;
        maxInvestors = _maxInvestors;
        // Set flag
        STO_PARAMS_ready = true;
    }


    function stagePrelaunch() 
        onlyAdmin onlyAtSetup public 
    {
        require(MAIN_PARAMS_ready, "MAIN_PARAMS not setted");
        require(STO_FLAGS_ready, "STO_FLAGS not setted");
        require(STO_PARAMS_ready, "STO_PARAMS not setted");

        if (beginningDate == 0) beginningDate = now;
        stage = Stage.PRELAUNCH;
    }

    function stageActivate() 
        onlyAdmin onlyAtPreLaunch public 
    {
        stage = Stage.ACTIVE;
    }

    // Feature #10: ADMIN FUNCTIONS


    // Feature #9
    function setLockupPeriod(uint256 _lockEnds)
        onlyAdmin public 
    {
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
    function addKYCResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(KYCResolverQ < 4, "There are already 5 resolvers for KYC");
        KYCResolverArray[KYCResolverQ] = _address;
        KYCResolverQ ++;
        //serviceRegistry.addService(address(this), bytes32("KYC"), _address);
    }
    function removeKYCResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        //serviceRegistry.replaceService(address(this), bytes32("KYC"), _address,address(0)); 
    }

    function addAMLResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(AMLResolverQ < 4, "There are already 5 resolvers for AML");
        AMLResolverArray[AMLResolverQ] = _address;
        AMLResolverQ ++;
        //serviceRegistry.addService(address(this), bytes32("AML"), _address);

    }
    function removeAMLResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        //serviceRegistry.replaceService(address(this), bytes32("AML"), _address,address(0)); 
    }

    function addLegalResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        require(LegalResolverQ < 4, "There are already 5 legal resolvers");
        LegalResolverArray[LegalResolverQ] = _address;
        LegalResolverQ ++;
        //serviceRegistry.addService(address(this), bytes32("LEGAL"), _address);
    }

    function removeLegalResolver(address _address) onlyAdmin onlyAtPreLaunch public {
        //serviceRegistry.replaceService(address(this), bytes32("LEGAL"), _address,address(0));
    }




    // Release gains. Only after escrow is released

    // Retrieve tokens and ethers
    function releaseHydroTokens() onlyAdmin escrowReleased public {
        uint256 thisBalance = hydroToken.balanceOf(address(this));
        require(thisBalance > 0, "There are not HydroTokens in this account");
        hydrosReleased = hydrosReleased + thisBalance;
        require(hydroToken.transfer(Owner, thisBalance));
    }

    function releaseEthers() onlyAdmin escrowReleased public {
        require(address(this).balance > 0, "There are not ethers in this account");
        ethersReleased = ethersReleased + address(this).balance;
        require(Owner.send(address(this).balance));
    }




    // PUBLIC FUNCTIONS FOR INVESTORS -----------------------------------------------------------------


    function buyTokens(string memory _coin, uint256 _amount) 
        onlyActive public payable 
        returns(bool) 
    {
        uint256 total;
        uint256 _ein = identityRegistry.getEIN(msg.sender);
        bytes32 HYDRO = keccak256(abi.encode("HYDRO"));
        bytes32 ETH =  keccak256(abi.encode("ETH"));
        bytes32 coin = keccak256(abi.encode(_coin));

        if (!investors[_ein].exist) {
            investorsQuantity++;
            investors[_ein].exist = true;
            require(investorsQuantity <= maxInvestors || maxInvestors == 0, "Maximum investors reached");
        }
 
        require(stage == Stage.ACTIVE, "Current stage is not active");

        // CHECKINGS (to be exported as  a contract)
        // Coin allowance
        if (coin == HYDRO) require(HYDRO_ALLOWED, "Hydro is not allowed");
        if (coin == ETH) require(ETH_ALLOWED, "Ether is not allowed");
        // Check for limits
        if (HYDRO_AMOUNT_TYPE && coin == HYDRO) {
            require(hydroReceived.add(_amount) <= hydroAllowed, "Hydro amount exceeded");
        }
        if (ETH_AMOUNT_TYPE && coin == ETH) {
            require((ethReceived + msg.value) <= ethAllowed, "Ether amount exceeded");
        }
        // Check with KYC and AML providers
        if (KYC_RESTRICTED && KYCResolverQ > 0) _checkKYC(msg.sender, _amount);
        if (AML_RESTRICTED && AMLResolverQ > 0) _checkAML(msg.sender, _amount);

        // Check with whitelist and blacklist
        if (WHITELIST_RESTRICTED) _checkWhitelist(msg.sender);
        if (BLACKLIST_RESTRICTED) _checkBlacklist(msg.sender);

        // Calculate total
        if (coin == HYDRO) {
            total = _amount.mul(hydroPrice) / 1 ether;
            investors[_ein].hydroSent = investors[_ein].hydroSent.add(_amount);
            hydroReceived = hydroReceived.add(_amount);      
        }

        if (coin == ETH) {
            total = msg.value.mul(ethPrice) / 1 ether;
            investors[_ein].etherSent += msg.value;
            ethReceived = ethReceived + msg.value;
        }

        // Check with maxSupply
        require(issuedTokens.add(total) <= maxSupply, "Max supply of Tokens is exceeded");

        // Check for ownership percentage 
        if (PERC_OWNERSHIP_TYPE) {
            require ((issuedTokens.add(total).mul(1 ether) / maxSupply) < percAllowedTokens, 
                "Perc ownership exceeded");
        }
        // Transfer Hydrotokens from buyer to this contract
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
        public pure 
        returns(bool) 
    {
        //return(interestSolver(msg.sender));
        return true;
    }



    // Token ERC-20 wrapper -----------------------------------------------------------

    // Feature #11
    function transfer(address _to, uint256 _amount) 
        isUnlocked isUnfreezed(msg.sender, _to) 
        public 
        returns(bool success) 
    {    
        if (KYC_RESTRICTED) _checkKYC(_to, _amount);
        if (AML_RESTRICTED) _checkAML(_to, _amount);
        // _updateBatches(msg.sender, _to, _amount);
        _doTransfer(msg.sender, _to, _amount);
        return true;
    }

    // Feature #11
    function transferFrom(address _from, address _to, uint256 _amount) 
        isUnlocked isUnfreezed(_from, _to) 
        public 
        returns(bool success) 
    { 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        if (KYC_RESTRICTED) _checkKYC(_to, _amount);
        if (AML_RESTRICTED) _checkAML(_to, _amount);
        // _updateBatches(_from, _to, _amount);
        _doTransfer(_from, _to, _amount);
        return true;
    }

    function balanceOf(address _from) public view returns(uint256) {
        return balance[_from];
    }

    function approve(address _spender, uint256 _amount) public returns(bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0), "Approved amount should be zero before changing it");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function authenticate(uint _value, uint _challenge, uint _partnerId) public {
        Raindrop raindrop = Raindrop(raindropAddress);
        raindrop.authenticate(msg.sender, _value, _challenge, _partnerId);
        _doTransfer(msg.sender, Owner, _value);
    }


    // PUBLIC GETTERS ----------------------------------------------------------------

    function isLocked() public view returns(bool) {
        return IS_LOCKED;
    }

    function isAlive() public view returns(bool) {
        if (!exists) return false;
        if (stage == Stage.SETUP && !isSetupTime()) return false;
        return true;
    }

    function isSetupTime() internal view returns(bool) {
        // 15 days to complete setup
        return((now - registerDate) < (15 * 24 * 60 * 60));
    }

    function isPrelaunchTime() internal view returns(bool) {
        // 15 days to complete setup
        return((now - registerDate) < (15 * 24 * 60 * 60));
    }



    // INTERNAL FUNCTIONS ----------------------------------------------------------

     function _doSell(address _to, uint256 _amount) private {
        issuedTokens = issuedTokens.add(_amount);
        balance[_to] = balance[_to].add(_amount);
    }

    function _doTransfer(address _from, address _to, uint256 _amount) internal {
        balance[_to] = balance[_to].add(_amount);
        balance[_from] = balance[_from].sub(_amount);
        emit Transfer(_from, _to, _amount);
    } 

    // Permissions checking

    // Feature #8
    function _checkKYC(address _to, uint256 _amount) private view {
        uint256 einTo = identityRegistry.getEIN(_to);
        for (uint8 i = 0; i < KYCResolverQ; i++) {
            ResolverInterface resolver = ResolverInterface(KYCResolverArray[i]);
            require(resolver.isApproved(einTo, _amount), "KYC not approved");
        }
    }
    function _checkAML(address _to, uint256 _amount) private view {
        uint256 einTo = identityRegistry.getEIN(_to);
        for (uint8 i = 0; i < AMLResolverQ; i++) {
            ResolverInterface resolver = ResolverInterface(AMLResolverArray[i]);
            require(resolver.isApproved(einTo, _amount));
        }
    }

    function _checkLegaL(address _to, uint256 _amount) private view {
        uint256 einTo = identityRegistry.getEIN(_to);
        for (uint8 i = 0; i < LegalResolverQ; i++) {
            ResolverInterface resolver = ResolverInterface(LegalResolverArray[i]);
            require(resolver.isApproved(einTo, _amount));
        }
    }

    function _checkWhitelist(address _user) private view {
        uint256 einUser = identityRegistry.getEIN(_user);
        require(whiteList[einUser], "EIN address not in whitelist");
    }

    function _checkBlacklist(address _user) private view {
        uint256 einUser = identityRegistry.getEIN(_user);
        require(!blackList[einUser], "EIN address is blacklisted");
    }

}
