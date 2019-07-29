pragma solidity ^0.5.0;


//import './components/SnowflakeOwnable.sol';
//import './components/TokenWithDates.sol';
import './components/HSTBuyerRegistry.sol';
import './interfaces/HydroInterface.sol';
import './interfaces/ResolverInterface.sol';
import './interfaces/IdentityRegistryInterface.sol';
//import './interfaces/SnowflakeViaInterface.sol';
import './zeppelin/math/SafeMath.sol';
import './zeppelin/ownership/Ownable.sol';
import './modules/SharesPaymentSystem.sol';

//interface IdentityRegistryInterface {
//    function getEIN(address _address) external view returns (uint ein);
//}

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
    bool public ETH_ORACLE;
    bool public HYDRO_ORACLE;
}

contract STO_PARAMS {
    bool public STO_PARAMS_ready;
    // @param percAllowedTokens: 100% = 1 ether, 50% = 0.5 ether
    uint256 public percAllowedTokens; // considered if PERC_OWNERSHIP_TYPE
    uint256 public hydroAllowed; // considered if HYDRO_AMOUNT_TYPE
    uint256 public ethAllowed; // considered if ETH_AMOUNT_TYPE
    uint256 public lockPeriod; // in days
    uint256 public minInvestors;
    uint256 public maxInvestors;
    address public ethOracle;
    address public hydroOracle;
}

contract STO_Interests {
    uint256 public marketStarted; // Date of market stage
    uint256[] internal periods;
}


contract HSToken is MAIN_PARAMS, STO_FLAGS, STO_PARAMS, STO_Interests, SharesPaymentSystem {

    using SafeMath for uint256;

    enum Stage {
        SETUP, PRELAUNCH, PRESALE, SALE, LOCK, MARKET, FINALIZED
    }

    // For date analysis
    struct Batch {
        uint initial; // Initial quantity received in a batch. Not modified in the future
        uint quantity; // Current quantity of tokens in a batch.
        uint age; // Creation of the batch (timestamp)
    }

// This is already declared in SharesPaymentSystem
//    struct Investor {
//        bool exists;
//        uint256 hydroSent;
//        uint256 lastPeriodPayed;
//    }

    // Basic states
    bool public exists; // Flag to deactivate it
    bool public locked; // Locked token transfers

	// Main parameters
    uint256 public registerDate; // Date of creation of token

	uint256 public id; // Unique HSToken id
	bytes32 public name;
	string public description;
	bytes32 public symbol;
    uint8 public decimals;
    address payable public Owner;
    uint256 public einOwner;
    address public createdBy;

    // State Memory
    Stage public stage; // SETUP, PRELAUNCH, PRESALE, SALE, LOCK, MARKET, FINALIZED
    bool public legalApproved;
    // uint256 public issuedTokens; // It is in the payment modules
    uint256 public burnedTokens;
    uint256 public hydroReceived;
    uint256 public ethReceived;
    uint256 public investorsQuantity;
    uint256 hydrosReleased; // Quantity of Hydros released by owner
    mapping(uint256 => uint256) issuedTokensAt;
    mapping(uint256 => uint256) hydroPriceAt;
    // mapping(uint256 => uint256) results; // It is in the payment module

 	// Links to Modules
	// address public RegistryRules;
    address public raindropAddress;

    // address InterestSolver;

    // Mappings
    mapping(uint256 => bool) public whitelist;
    mapping(uint256 => bool) public blacklist;
    mapping(uint256 => bool) public freezed;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(uint256 => Investor) public investors;

    // Balances
    mapping(address => uint256) public balance;
    // mapping(uint256 => mapping(address => uint256)) public balanceAt; // It is at the payment module

    // Escrow contract's address => security number
    // mapping(address => uint256) public escrowContracts;
    // address[] public escrowContractsArray;

    // Declaring interfaces
    IdentityRegistryInterface public IdentityRegistry;
    HydroInterface public HydroToken;
    HSTBuyerRegistry public BuyerRegistry;
    // SnowflakeViaInterface public snowflakeVia;
    // TokenWithDates private tokenWithDates;

    event HydroSTCreated(
        uint256 indexed id,
        bytes32 name,
        bytes32 symbol,
        uint8 decimals,
        uint256 einOwner
        );

    event PaymentPeriodBoundariesAdded(
    	uint256[] _periods
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
        require(!locked, "Token locked");
        if (PERIOD_LOCKED) require (now > lockEnds, "Locked period active");
        _;
    }

    modifier isUnfreezed(address _from, address _to) {
        require(!freezed[IdentityRegistry.getEIN(_to)], "Target EIN is freezed");
        require(!freezed[IdentityRegistry.getEIN(_from)], "Source EIN is freezed");
        _;
    }

    modifier onlyAtPreLaunch() {
        require(stage == Stage.PRELAUNCH, "Not in Prelaunch stage");
        require(beginningDate == 0 || beginningDate > now, "Prelaunch time has passed");
    	_;
    }

    modifier onlyActive() {
        require(stage == Stage.MARKET, "Not in active stage");
        require(endDate > now, "Issuing stage finalized");
        _;
    }

    modifier onlyAdmin() {
        // Check if EIN of sender is the same as einOwner
        require(IdentityRegistry.getEIN(msg.sender) == einOwner, "Only for admins");
        _;
    }

    modifier escrowReleased() {
        require(escrowLimitPeriod < now, "Escrow limit period is still active");
        require(legalApproved, "Legal conditions are not met");
        _;
    }

    modifier onlyAtSetup() {
        require(stage == Stage.SETUP, "Stage is not setup");
        _;
    }

    constructor(
        uint256 _id,
        bytes32 _name,
        string memory _description,
        bytes32 _symbol,
        uint8 _decimals,
        address _hydroToken,
        address _identityRegistry,
        address _buyerRegistry,
        address payable _owner
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
        // locked = true;

        // State Memory
        stage = Stage.SETUP;

        periods.push(now);
        // Links to Modules
        // RegistryRules = 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20;
        // InterestSolver = address(0x0);

        HydroToken = HydroInterface(_hydroToken); // 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20
        IdentityRegistry = IdentityRegistryInterface(_identityRegistry); // 0xa7ba71305bE9b2DFEad947dc0E5730BA2ABd28EA
        BuyerRegistry = HSTBuyerRegistry(_buyerRegistry);
        // raindropAddress = _RaindropAddress;

        Owner = _owner;
        einOwner = IdentityRegistry.getEIN(Owner);
        createdBy = msg.sender;

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
        public onlyAdmin onlyAtSetup
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
        require(!MAIN_PARAMS_ready, "Params already setted");
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
        bool _PERIOD_LOCKED,
        bool _PERC_OWNERSHIP_TYPE,
        bool _HYDRO_AMOUNT_TYPE,
        bool _ETH_AMOUNT_TYPE,
        bool _HYDRO_ALLOWED,
        bool _ETH_ALLOWED,
        bool _KYC_RESTRICTED,
        bool _AML_RESTRICTED,
        bool _WHITELIST_RESTRICTED,
        bool _BLACKLIST_RESTRICTED,
        bool _ETH_ORACLE,
        bool _HYDRO_ORACLE
    )
        public onlyAdmin onlyAtSetup
    {
        require(!STO_FLAGS_ready, "Flags already setted");
        // Load values
        LIMITED_OWNERSHIP = _LIMITED_OWNERSHIP;
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
        ETH_ORACLE = _ETH_ORACLE;
        HYDRO_ORACLE = _HYDRO_ORACLE;
        // Set flag
        STO_FLAGS_ready = true;
    }

    function set_STO_PARAMS(
        uint256 _percAllowedTokens,
        uint256 _hydroAllowed,
        uint256 _ethAllowed,
        uint256 _lockPeriod,
        uint256 _minInvestors,
        uint256 _maxInvestors,
        address _ethOracle,
        address _hydroOracle
    )
        public onlyAdmin onlyAtSetup
    {
        require(!STO_PARAMS_ready, "Params already setted");
        require(STO_FLAGS_ready, "STO_FLAGS has not been set");
        // Load values
        percAllowedTokens = _percAllowedTokens;
        hydroAllowed = _hydroAllowed;
        ethAllowed = _ethAllowed;
        lockPeriod = _lockPeriod;
        minInvestors = _minInvestors;
        maxInvestors = _maxInvestors;
        ethOracle = _ethOracle;
        hydroOracle = _hydroOracle;
        // Set flag
        STO_PARAMS_ready = true;
    }


    // ADMIN STAGES CHANGING

    function stagePrelaunch()
        public onlyAdmin onlyAtSetup
    {
        require(MAIN_PARAMS_ready, "MAIN_PARAMS not setted");
        require(STO_FLAGS_ready, "STO_FLAGS not setted");
        require(STO_PARAMS_ready, "STO_PARAMS not setted");

        if (beginningDate == 0) beginningDate = now;
        stage = Stage.PRELAUNCH;
    }

    function stagePresale()
        public onlyAdmin
    {
    	require(stage == Stage.PRELAUNCH, "Stage should be Prelaunch");
        stage = Stage.PRESALE;
    }

    function stageSale()
        public onlyAdmin
    {
    	require(stage == Stage.PRESALE, "Stage should be Presale");
        stage = Stage.SALE;
    }

    function stageLock()
        public onlyAdmin
    {
    	require(stage == Stage.SALE, "Stage should be Sale");
        stage = Stage.LOCK;
    }


    function stageMarket()
    	public onlyAdmin 
    {
    	require(stage == Stage.LOCK, "Stage should be Lock");
    	stage = Stage.MARKET;
    	marketStarted = now;
    }



    // Feature #10: ADMIN FUNCTIONS

    function getTokenEINOwner() public view returns(uint) {
        return einOwner;
    }

    function getTokenOwner() public view returns(address) {
        return Owner;
    }


    // Feature #9
    function setLockupPeriod(uint256 _lockEnds)
        public onlyAdmin
    {
    	require(lockEnds > now, "Lock ending should be in the future");

        if (_lockEnds == 0) {
            PERIOD_LOCKED = false;
            }

        PERIOD_LOCKED = true;
        lockEnds = _lockEnds;
    }


    function changeBuyerRegistry(address _newBuyerRegistry) public onlyAdmin {
    	require(stage == Stage.SETUP, "Stage should be Setup to change this");
		BuyerRegistry = HSTBuyerRegistry(_newBuyerRegistry);
    }

    function lock() public onlyAdmin {
        locked = true;
    }

    function unLock() public onlyAdmin {
        locked = false;
    }

    function addWhitelist(uint256[] memory _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          whitelist[_einList[i]] = true;
        }
    }

    function addBlacklist(uint256[] memory _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          blacklist[_einList[i]] = true;
        }
    }

    function removeWhitelist(uint256[] memory _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          whitelist[_einList[i]] = false;
        }

    }

    function removeBlacklist(uint256[] memory _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          blacklist[_einList[i]] = false;
        }
    }

    function freeze(uint256[] memory _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          freezed[_einList[i]] = true;
        }
    }

    function unFreeze(uint256[] memory _einList) public onlyAdmin {
        for (uint i = 0; i < _einList.length; i++) {
          freezed[_einList[i]] = false;
        }
    }


    function addPaymentPeriodBoundaries(uint256[] memory _periods) public onlyAdmin {
        for (uint i = 0; i < _periods.length; i++) {
          // require(periods[periods.length-1] < _periods[i], "Period must be after previous one"); 
          periods.push(_periods[i]);
        }
        emit PaymentPeriodBoundariesAdded(_periods);
    }


    function getPaymentPeriodBoundaries() public view returns(uint256[] memory) {
    	return periods;
    }


    // Only at Prelaunch functions:

    // Setting oracles

    function addEthOracle(address _newAddress) public onlyAdmin {
    	ethOracle = _newAddress;
    }

    function addHydroOracle(address _newAddress) public onlyAdmin {
    	hydroOracle = _newAddress;
    }

    // Release gains. Only after escrow is released

    // Retrieve tokens and ethers
    function releaseHydroTokens() public onlyAdmin escrowReleased {
        uint256 thisBalance = HydroToken.balanceOf(address(this));
        require(thisBalance > 0, "There are not HydroTokens in this account");
        hydrosReleased = hydrosReleased + thisBalance;
        require(HydroToken.transfer(Owner, thisBalance), "Error while releasing Tokens");
    }


    // PUBLIC FUNCTIONS FOR INVESTORS -----------------------------------------------------------------


    function buyTokens(uint256 _amount)
        public onlyActive payable
        returns(bool)
    {
        uint256 total;
        uint256 _ein = IdentityRegistry.getEIN(msg.sender);
        // bytes32 HYDRO = keccak256(abi.encode("HYDRO"));
        // bytes32 ETH = keccak256(abi.encode("ETH"));

        if (!investors[_ein].exists) {
            investorsQuantity++;
            investors[_ein].exists = true;
            require(investorsQuantity <= maxInvestors || maxInvestors == 0, "Maximum investors reached");
        }

        require(stage == Stage.MARKET, "Current stage is not active");

        // CHECKINGS (to be replaced by HSTRulesEnforcer)
        // Check for limits
        if (HYDRO_AMOUNT_TYPE) {
            require(hydroReceived.add(_amount) <= hydroAllowed, "Hydro amount exceeded");
        }

        // Check with KYC and AML providers
        BuyerRegistry.checkRules(_ein);

        // Check with whitelist and blacklist
        if (WHITELIST_RESTRICTED) _checkWhitelist(msg.sender);
        if (BLACKLIST_RESTRICTED) _checkBlacklist(msg.sender);

        // Calculate total
        total = _amount.mul(hydroPrice) / 1 ether;
        investors[_ein].hydroSent = investors[_ein].hydroSent.add(_amount);
        hydroReceived = hydroReceived.add(_amount);

        // Check with maxSupply
        require(issuedTokens.add(total) <= maxSupply, "Max supply of Tokens is exceeded");

        // Check for ownership percentage
        if (PERC_OWNERSHIP_TYPE) {
            require ((issuedTokens.add(total).mul(1 ether) / maxSupply) < percAllowedTokens,
                "Perc ownership exceeded");
        }

        // Transfer Hydrotokens from buyer to this contract
        require(HydroToken.transferFrom(msg.sender, address(this), _amount),
            "Hydro transfer was not possible");

        // _updateBatches(address(0), _to, _amount);
        // Sell
        _doSell(msg.sender, total);
        emit Sell(msg.sender, total);
        return true;
    }

    // To be accesed by modules
    function _getEIN(address _address) private view returns(uint256) {
        return IdentityRegistry.getEIN(_address);
    }

    function _transferHydroToken(address _address, uint256 _payment) private returns(bool) {
        return HydroToken.transfer(_address, _payment);
    }


    // Token ERC-20 wrapper -----------------------------------------------------------

    // Feature #11
    function transfer(address _to, uint256 _amount)
        public isUnlocked isUnfreezed(msg.sender, _to)
        returns(bool success)
    {
        BuyerRegistry.checkRules(IdentityRegistry.getEIN(_to));

        _doTransfer(msg.sender, _to, _amount);
        return true;
    }

    // Feature #11
    function transferFrom(address _from, address _to, uint256 _amount)
        public isUnlocked isUnfreezed(_from, _to)
        returns(bool success)
    {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

        BuyerRegistry.checkRules(IdentityRegistry.getEIN(_to));

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

    function isTokenLocked() public view returns(bool) {
        if (locked) return true;
        if (PERIOD_LOCKED && now < lockEnds) return true;
        return false;
    }

    function isTokenAlive() public view returns(bool) {
        if (!exists) return false;
        if (stage == Stage.SETUP && !tokenInSetupStage()) return false;
        return true;
    }

    function getTokenStage() public view returns(string memory _stage) {
        if (stage == Stage.FINALIZED || stage == Stage.MARKET && endDate < now) return "FINALIZED";
        if (stage == Stage.MARKET || stage == Stage.PRELAUNCH && beginningDate > 0 && beginningDate > now) return "ACTIVE";
        if (stage == Stage.PRELAUNCH) return "PRELAUNCH";
        if (stage == Stage.SETUP && tokenInSetupStage()) return "SETUP";
        return "TOKEN IS INACTIVE";
    }

    function getNow() public view returns(uint256) {
    	return now;
    }

    // PRIVATE GETTERS

    function tokenInSetupStage() private view returns(bool) {
        // 15 days to complete setup
        return((now - registerDate) < (15 * 24 * 60 * 60));
    }

    function tokenInPrelaunchStage() private view returns(bool) {
        // 15 days to complete setup
        return((now - registerDate) < (15 * 24 * 60 * 60));
    }


    // ONLY FOR ORACLES

    function updateHydroPrice(uint256 _newPrice) external {
    	require(msg.sender == hydroOracle, "This can only be executed by the registered Oracle");
    	hydroPrice = _newPrice;
    }

    // PRIVATE FUNCTIONS ----------------------------------------------------------

     function _doSell(address _to, uint256 _amount) private {
        issuedTokens = issuedTokens.add(_amount);
        issuedTokensAt[0] = issuedTokens;
        balance[_to] = balance[_to].add(_amount);
        balanceAt[0][_to] = balance[_to];
    }

    function _doTransfer(address _from, address _to, uint256 _amount) private {
    	uint256 _period = _getPeriod();
        balance[_to] = balance[_to].add(_amount);
        balance[_from] = balance[_from].sub(_amount);
        balanceAt[_period][_to] = balance[_to];
        balanceAt[_period][_from] = balance[_from];
        emit Transfer(_from, _to, _amount);
    }

    function _getPeriod() public view returns(uint256) {
    	if (periods.length < 2) return 0;
    	for (uint i = 1; i < periods.length; i++) {
          if (periods[i] > now) return i-1;
        }
     	return 0;
    }

    function _checkWhitelist(address _user) private view {
        uint256 einUser = IdentityRegistry.getEIN(_user);
        require(whitelist[einUser], "EIN address not in whitelist");
    }

    function _checkBlacklist(address _user) private view {
        uint256 einUser = IdentityRegistry.getEIN(_user);
        require(!blacklist[einUser], "EIN address is blacklisted");
    }

}
