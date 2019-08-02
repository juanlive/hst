pragma solidity ^0.5.0;

import '../interfaces/HydroInterface.sol';
import '../zeppelin/math/SafeMath.sol';


contract SharesPaymentSystem {

    using SafeMath for uint256;

    struct Investor {
        bool exists;
        uint256 hydroSent;
        uint256 lastPeriodPayed;
    }

    bool public EXT_PARAMS_ready;

    string public fundName;
    string public registerNumber;
    string public jurisdiction;
    address payable fundManager;
    uint256 public carriedInterestRate;


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


    // Case A: Shares
    function claimPayment()
        public
    {
        uint256 _ein = _getEIN(msg.sender);
        uint256 _period = _getPeriod();
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

    function notifyPeriodProfit(uint256 _profits) public {
        require(msg.sender == hydroOracle, "Only registered oracle can notify profits");
        require(_profits > 0, "Profits has to be greater than zero");
        uint256 _period = _getPeriod();
        require(profits[_period] == 0, "Period already notified");
        profits[_period] = _profits;
        uint256 _paymentForManager = _profits.mul(carriedInterestRate) / 1 ether;
        require(_profits <= _hydroTokensBalance().sub(_paymentForManager), "There is not enough HydroTokens to pay");
        require(_transferHydroToken(msg.sender, _paymentForManager), "Error while releasing Tokens");
        emit PeriodNotified(_period, _profits);
    }


    function setFundProperties(
        string memory _fundName,
        string memory _registerNumber,
        string memory _jurisdiction,
        address payable _fundManager,
        uint256 _carriedInterestRate
        ) public 
    {
        require(_getEIN(msg.sender) == _getTokenOwner(), "Only for token owner");
        require(_getStage() == 0, "Only at Setup stage");

        fundName = _fundName;
        registerNumber = _registerNumber;
        jurisdiction = _jurisdiction;
        fundManager = _fundManager;
        carriedInterestRate = _carriedInterestRate;

        EXT_PARAMS_ready = true; // To allow passing to Prelaunch stage
    }


    function _balanceAt(uint256 _period, address _address) private view returns(uint256) {
        for (uint256 i = _period; i > 0; i--) {
            if (balanceAt[i][_address] > 0) {
                return balanceAt[i][_address];
            }
        }
        return 0;
    }



    // Dummy functions (to be overwritten by main contract)
    function _getPeriod() public view returns(uint256) {}
    function _getEIN(address) private view returns(uint256) {}
    function _getStage() private view returns(uint256) {}
    function _getTokenOwner() private view returns(uint256) {}
//    function _issuedTokens() internal view returns(uint256);
    function _transferHydroToken(address, uint256) private returns(bool);
    function _hydroTokensBalance() private returns(uint256);

}