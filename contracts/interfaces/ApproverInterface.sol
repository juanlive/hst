pragma solidity ^0.5.4;

interface ApproverInterface {
    function isApproved(address _to, uint256 _amount) external view returns (bool);
}
