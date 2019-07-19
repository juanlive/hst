pragma solidity ^0.5.0;


contract SharesPaymentSystem {

    struct Investor {
        bool exists;
        uint256 hydroSent;
        uint256 lastPeriodPayed;
    }

    // mapping(address => uint256) public balance;
    mapping(uint256 => mapping(address => uint256)) public balanceAt;
    mapping(uint256 => uint256) issuedTokensAt;
    mapping(uint256 => uint256) results;
    mapping(uint256 => Investor) public investors;
    address public hydroOracle;
    uint256 issuedTokens;


    // Case A: Shares
    function claimPayment()
        public view
        returns(uint256)
    {
        //return uint(address(IdentityRegistry));
        uint256 _ein = _getEIN(msg.sender);
        uint256 _period = _getPeriod();
        uint256 _periodToPay = investors[_ein].lastPeriodPayed + 1;
        require(_periodToPay <= _period, "There is no period to pay yet");

        //investors[_ein].lastPeriodPayed = _periodToPay;
        //return _balanceAt(_periodToPay, msg.sender);
        //return (_balanceAt(_period, msg.sender), issuedTokens, results[_period]);

        uint256 _participationRate = _balanceAt(_period, msg.sender) * 1 ether / issuedTokens;

        //return (_balanceAt(_periodToPay, msg.sender), issuedTokens, results[_period]);

        uint256 _paymentForInvestor = results[_period] * _participationRate / 1 ether;

        //require(HydroToken.transfer(msg.sender, _paymentForInvestor), "Error while releasing Tokens");
        return _paymentForInvestor;
    }

    function notifyPeriodResults(uint256 _results) public {
        require(msg.sender == hydroOracle, "Only registered oracle can notify results");
        require(_results > 0, "Results has to be greater than zero");
        uint256 _period = _getPeriod();
        require(results[_period] == 0, "Period already notified");
        results[_period] = _results;
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
    function _getEIN(address _address) private view returns(uint256) {}
    function _issuedTokens() internal view returns(uint256) {}

}