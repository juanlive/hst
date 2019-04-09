pragma solidity ^0.5.0;


contract KMLApprover {


	mapping(uint256 => bool) public rejectedEin;


    constructor(uint256 _rejected) public {
        rejectedEin[_rejected] = true;
    }


    function isApproved(uint256 _ein, uint256 _amount) external view returns (bool) {
        if (rejectedEin[_ein]) return false;
        return true;
    }


    function rejectEin(uint256 _ein) public {
    	rejectedEin[_ein] = true;
    }


}
