pragma solidity ^0.5.4;


contract KMLApprover {


    constructor(uint256 _rejected) public {
        rejectedEin = _rejected;
    }


    function isApproved(uint256 _ein, uint256 _amount) external view returns (bool) {
        if (_ein == rejectedEin) return false;
        return true;
    }


}
