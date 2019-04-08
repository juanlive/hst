pragma solidity ^0.5.4;

import './HydroSecuritiesToken.sol';
import './HSTIssuer.sol';
import './components/HSTEscrow.sol';
import './components/SnowflakeOwnable.sol';
import './interfaces/IdentityRegistryInterface.sol';

/*********************************
 * Hydro token on Rinkeby blockchain
 *********************************
 *
 * Token contract Rinkeby: 
 * 0x4959c7f62051d6b2ed6eaed3aaee1f961b145f20
 * Nº decimals: 18
 * Symbol: HYDRO
 *
 * Snowflake contract Rinkeby
 * 0xb0d5a36733886a4c5597849a05b315626af5222e
 *
 * IdentityRegistry contract Rinkeby
 * 0xa7ba71305be9b2dfead947dc0e5730ba2abd28ea
 *
 */

/**
 * @title HSTFactory
 * @notice Contract deployer for the issuance of Securities
 * @dev 
 * @author Fatima Castiglione Maldonado <castiglionemaldonado@gmail.com>
 */
contract HSTFactory is SnowflakeOwnable {

    address token;
    address issuer;
    address escrow;

    /// @notice Constructor
    constructor() public {
    }

    event SecuritiesDeployed(bytes32 _name, string _description);
    event ContractDeployed(bytes32 _name, bytes32 _type, address indexed _addr);

    // deploy a new Securities Token contract set
    function deploySecuritiesTokenContractSet() public payable onlySnowflakeOwner returns(bool) {
        token = deployToken;
        issuer = deployIssuer;
        escrow = deployEscrow;
    }

    // deploy a new Securities Token contract
    function deployToken(bytes32 _name) public payable onlySnowflakeOwner returns(address) {
		HydroSecuritiesToken _token = (new HydroSecuritiesToken).value(msg.value)(address(msg.sender));
		emit ContractDeployed(_name, "TOKEN", _token);
		return _token;
    }

    // deploy a new Securities Issuer contract
    function deployIssuer(bytes32 _name) public payable onlySnowflakeOwner returns(address) {
		HSTIssuer _issuer = (new HSTIssuer).value(msg.value)(address(msg.sender));
		emit ContractDeployed(_name, "ISSUER", _issuer);
		return _issuer;
    }

    // deploy a new Securities Escrow contract
    function deployEscrow(bytes32 _name) public payable onlySnowflakeOwner returns(address) {
		HSTEscrow _escrow = (new HSTEscrow).value(msg.value)(address(msg.sender));
		emit ContractDeployed(_name, "ESCROW", _escrow);
		return _escrow;
    }

}
