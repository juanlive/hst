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

    // mapping(address => uint256) public balance;
    mapping(uint256 => mapping(address => uint256)) public balanceAt;
    mapping(uint256 => uint256) issuedTokensAt;
    mapping(uint256 => uint256) results;
    mapping(uint256 => Investor) public investors;
    address public hydroOracle;
    uint256 issuedTokens;


    event SharesPayed(
        uint256 indexed investorEin, 
        uint256 periodToPay, 
        uint256 periodResults, 
        uint256 investorParticipationRate,
        uint256 paymentForInvestor
        );

    event PeriodNotified(
        uint256 period,
        uint256 results
        );


    constructor() public {
        EXT_PARAMS_ready = true; // To allow passing to Prelaunch stage
    }

    // Case A: Shares
    function claimPayment()
        public
    {
        //return uint(address(IdentityRegistry));
        uint256 _ein = _getEIN(msg.sender);
        uint256 _period = _getPeriod();
        uint256 _periodToPay = investors[_ein].lastPeriodPayed + 1;
        require(_periodToPay <= _period, "There is no period to pay yet");

        investors[_ein].lastPeriodPayed = _periodToPay;

        uint256 _participationRate = _balanceAt(_periodToPay, msg.sender) * 1 ether / issuedTokens;
        uint256 _paymentForInvestor = results[_periodToPay] * _participationRate / 1 ether;

        if (_paymentForInvestor > 0) {
            require(_transferHydroToken(msg.sender, _paymentForInvestor), "Error while releasing Tokens");
            }
        emit SharesPayed(_ein, _periodToPay, results[_periodToPay], _participationRate, _paymentForInvestor);
    }

    function notifyPeriodResults(uint256 _results) public {
        require(msg.sender == hydroOracle, "Only registered oracle can notify results");
        require(_results > 0, "Results has to be greater than zero");
        uint256 _period = _getPeriod();
        require(results[_period] == 0, "Period already notified");
        results[_period] = _results;
        emit PeriodNotified(_period, _results);
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
//    function _issuedTokens() internal view returns(uint256);
    function _transferHydroToken(address, uint256) private returns(bool);

}