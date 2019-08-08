pragma solidity ^0.5.0;

import '../interfaces/HydroInterface.sol';
import '../zeppelin/math/SafeMath.sol';


contract PaymentSystem {

    using SafeMath for uint256;

    enum STOTypes {
        SHARES, UNITS, BONDS
    }

    struct Investor {
        bool exists;
        uint256 hydroSent;
        uint256 lastPeriodPayed;
    }

    STOTypes public stoType;

    string public issuerName;
    string public registeredNumber;
    string public jurisdiction;

    // For Units
    address payable fundManager;
    uint256 public carriedInterestRate;

    // Flag to set this configuration ready
    bool public EXT_PARAMS_ready;
    // Flags to set EXT_PARAMS_ready in Bonds
    bool ISSUER_PROPS_ready;
    bool BONDS_PROPS_ready;

    // mapping(address => uint256) public balance;
    mapping(uint256 => mapping(address => uint256)) public balanceAt;
    mapping(uint256 => uint256) issuedTokensAt;
    mapping(uint256 => uint256) profits;
    mapping(uint256 => Investor) public investors;
    address public hydroOracle;
    uint256 issuedTokens;


    event SharesPayed(
        uint256 indexed investorEin, 
        uint256 periodToPay, 
        uint256 periodProfits, 
        uint256 investorParticipationRate,
        uint256 paymentForInvestor
        );

    event PeriodNotified(
        uint256 period,
        uint256 profits
        );



    // PUBLIC SETTERS FOR SETUP STAGE, only for admin -----------------------------------------------------------

    function setIssuerProperties(
        string memory _issuerName,
        string memory _registeredNumber,
        string memory _jurisdiction,
        address payable _fundManager, // Can be 0x0 for Shares and Bonds
        uint256 _carriedInterestRate // Can be 0 for Shares and Bonds
        ) public 
    {
        require(_getEIN(msg.sender) == _getTokenEinOwner(), "Only for token owner");
        require(tokenInSetupStage(), "Only at Setup stage");

        if (stoType == STOTypes.UNITS) {
            require(_fundManager != address(0x0), "fundManager address is required");
            require(_carriedInterestRate > 0, "carriedInterestRate should be grater than zero");
        }

        issuerName = _issuerName;
        registeredNumber = _registeredNumber;
        jurisdiction = _jurisdiction;
        fundManager = _fundManager;
        carriedInterestRate = _carriedInterestRate;

        ISSUER_PROPS_ready = true;

        if (stoType != STOTypes.BONDS || BONDS_PROPS_ready) {
            EXT_PARAMS_ready = true; // Allow passing to Prelaunch stage
        }
    }

    function setBondsProperties() public {
        require(_getEIN(msg.sender) == _getTokenEinOwner(), "Only for token owner");
        require(tokenInSetupStage(), "Only at Setup stage");
        require(stoType == STOTypes.BONDS, "Configuration only for Bonds");

        // Set bonds properties
        //
        //
        //

        BONDS_PROPS_ready = true;

        if (ISSUER_PROPS_ready) {
            EXT_PARAMS_ready = true; // Allow passing to Prelaunch stage
        }
    }


    // PUBLIC FUNCTION FOR INVESTORS --------------------------------------------------------------------------

    function claimPayment()
        public
    {
        uint256 _ein = _getEIN(msg.sender);
        uint256 _period = getPeriod();
        uint256 _periodToPay = investors[_ein].lastPeriodPayed + 1;
        require(_periodToPay <= _period, "There is no period to pay yet");

        investors[_ein].lastPeriodPayed = _periodToPay;

        uint256 _participationRate = _balanceAt(_periodToPay, msg.sender) * 1 ether / issuedTokens;
        uint256 _paymentForInvestor = profits[_periodToPay] * _participationRate / 1 ether;

        if (_paymentForInvestor > 0) {
            require(_transferHydroToken(msg.sender, _paymentForInvestor), "Error while releasing Tokens");
            }
        emit SharesPayed(_ein, _periodToPay, profits[_periodToPay], _participationRate, _paymentForInvestor);
    }


    // FUNCTION FOR ORACLE UPDATES ----------------------------------------------------------------------------

    function notifyPeriodProfits(uint256 _profits) public {
        require(msg.sender == hydroOracle, "Only registered oracle can notify profits");
        require(_profits > 0, "Profits has to be greater than zero");
        uint256 _period = getPeriod();
        require(profits[_period] == 0, "Period already notified");

        profits[_period] = _profits;

        if (stoType == STOTypes.UNITS) {
            uint256 _paymentForManager = _profits.mul(carriedInterestRate) / 1 ether;
            require(_profits <= _hydroTokensBalance().sub(_paymentForManager), "There is not enough HydroTokens to pay");
            require(_transferHydroToken(msg.sender, _paymentForManager), "Error while releasing Tokens");
        }

        emit PeriodNotified(_period, _profits);
    }

    // INTERNAL FUNCTIONS ---------------------------------------------------------------------

    function _balanceAt(uint256 _period, address _address) private view returns(uint256) {
        for (uint256 i = _period; i > 0; i--) {
            if (balanceAt[i][_address] > 0) {
                return balanceAt[i][_address];
            }
        }
        return 0;
    }

    // Dummy functions (to be overwritten by main contract)
    function getPeriod() public view returns(uint256);
    function _getEIN(address) private view returns(uint256);
    function _getTokenEinOwner() private view returns(uint256);
    function tokenInSetupStage() private view returns(bool);
    function _transferHydroToken(address, uint256) private returns(bool);
    function _hydroTokensBalance() private view returns(uint256);

}