pragma solidity ^0.5.4;

import '../interfaces/HydroInterface.sol';
import '../HydroSecuritiesToken.sol';

/**
 * @title HydroEscrow
 * @notice Stores HYDRO inside as an escrow for HST issuing. This contracts stores any funds sent by the token creator and the funds that users pay to participate in the issuing. It distributes any refunds, and the corresponding dividends and interests to their receivers.
 * @dev
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HydroEscrow {
    uint256 public issuingEndingTimestamp;
    address public hydroSecurityTokenAddress;
    address public hydroTokenAddress;
    uint256 public totalHydroCapitalization;
    address payable public hydroCapitalReceiver;
    HydroInterface public hydroToken;
    HydroSecuritiesToken public hydroSecuritiesToken;

    modifier onlyHydroSecurityToken() {
        require(msg.sender == hydroSecurityTokenAddress, 'This function can only be executed by the original HydroSecurityToken');
        _;
    }

    // Set all initial variables
    constructor(uint256 _issuingEndingTimestamp, address _hydroSecurityTokenAddress, uint256 _totalHydroCapitalization, address payable _hydroCapitalReceiver) public {
        require(_issuingEndingTimestamp > now, 'The token issuing must end after now');
        require(_hydroSecurityTokenAddress != address(0), 'You must set the token address');
        require(_totalHydroCapitalization > 0, 'The total capitalization must be larger than zero');
        require(_hydroCapitalReceiver != address(0), 'You must set a capital receiver');
        issuingEndingTimestamp = _issuingEndingTimestamp;
        hydroSecurityTokenAddress = msg.sender;
        hydroSecurityToken = HydroTokenTestnetInterface(_hydroSecurityTokenAddress);
        hydroCapitalReceiver = _hydroCapitalReceiver;
    }

    // Send the collected capital to the capital receiver
    function releaseCollectedCapital() public onlyHydroSecurityToken {
        require(now >= endTimestamp, 'You can only release funds after the token issuing has ended');
        uint256 hydroInsideThisContract = hydroToken.balanceOf(address(this));

        // If there is no fee, the winner gets all including the ticket prices accomulated + the standard reward, if there's a fee, the winner gets his reward + the ticket prices accomulated - the fee percentage
        // if(fee == 0) {
        //     hydroForFeeReceiver = 0;
        //     hydroForWinner = hydroInsideThisContract;
        // } else {
        //     hydroForFeeReceiver = hydroInsideThisContract * (fee / 100);
        //     hydroForWinner = hydroInsideThisContract - hydroForFeeReceiver;
        // }

        // hydroToken.transfer(_winner, hydroForWinner);
        // hydroToken.transfer(feeReceiver, hydroForFeeReceiver);
        hydroToken.transfer(hydroCapitalReceiver, hydroInsideThisContract);
    }
}
