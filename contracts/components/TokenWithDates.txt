pragma solidity ^0.5.0;

/*********************************************************************************
 *********************************************************************************
 *
 * Token with a date
 * ERC20 token with capability to register the date of each lot of tokens received 
 *
 *********************************************************************************
 ********************************************************************************/

 /* ERC20 contract interface */

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


// The Token
contract TokenWithDates {

    // Token public variables
    string public name;
    string public symbol;
    uint8 public decimals; 
    string public version;
    uint256 public totalSupply;
    uint public price;
    bool public locked;
    uint multiplier;

    address public rootAddress;
    address public owner;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    mapping(address => uint) public maxIndex; // To store index of last batch: points to the next one
    mapping(address => uint) public minIndex; // To store index of first batch
    mapping(address => mapping(uint => Batch)) public batches; // To store batches with quantities and ages

    struct Batch {
    	uint initial; // Initial quantity received in a batch. Not modified in the future
        uint quant; // Current quantity of tokens in a batch.
        uint age; // Birthday of the batch
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    // Modifiers

    modifier onlyOwner() {
        if ( msg.sender != rootAddress && msg.sender != owner ) revert();
        _;
    }

    modifier onlyRoot() {
        if ( msg.sender != rootAddress ) revert();
        _;
    }

    modifier isUnlocked() {
    	if ( locked && msg.sender != rootAddress && msg.sender != owner ) revert();
		_;    	
    }


    // Safe math
    function safeAdd(uint x, uint y) internal returns (uint z) {
        require((z = x + y) >= x);
    }

    function safeSub(uint x, uint y) internal returns (uint z) {
        require((z = x - y) <= x);
    }

    function softSub(uint x, uint y) internal returns (uint z) {
        z = x - y;
        if (z > x ) z = 0;
    }

    // Token constructor
    constructor() public {        
        locked = false;
        name = 'TokenWithADate'; 
        symbol = 'TWD';
        version = "0.1"; 
        decimals = 18; 
        multiplier = 10 ** uint(decimals);
        totalSupply = 10000000 * multiplier; // 10,000,000 tokens
        rootAddress = msg.sender;        
        owner = msg.sender;
        balances[rootAddress] = totalSupply; 
        batches[rootAddress][0].initial = totalSupply;
        batches[rootAddress][0].quant = totalSupply;
        batches[rootAddress][0].age = now;
        maxIndex[rootAddress] = 1;
    }

    // Only root function
    function changeRoot(address _newRootAddress) onlyRoot public returns(bool){
        rootAddress = _newRootAddress;
        return true;
    }

    // Only owner functions

    // To send ERC20 tokens sent accidentally
    function sendToken(address _token,address _to , uint _value) onlyOwner public returns(bool) {
        ERC20Basic Token = ERC20Basic(_token);
        require(Token.transfer(_to, _value));
        return true;
    }

    function changeOwner(address _newOwner) onlyOwner public returns(bool) {
        owner = _newOwner;
        return true;
    }
       
    function unlock() onlyOwner public returns(bool) {
        locked = false;
        return true;
    }

    function lock() onlyOwner public returns(bool) {
        locked = true;
        return true;
    }

    // Public token functions
    // Standard function transfer
    function transfer(address _to, uint _value) isUnlocked public returns (bool success) {
        require(msg.sender != _to);
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);

        updateBatches(msg.sender, _to, _value);
        emit Transfer(msg.sender,_to,_value);
        return true;
        }


    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_from != _to);
        if ( locked && msg.sender != owner && msg.sender != rootAddress ) return false; 
        if ( balances[_from] < _value ) return false; // Check if the sender has enough
    	if ( _value > allowed[_from][msg.sender] ) return false; // Check allowance

        balances[_from] = safeSub(balances[_from] , _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to] , _value); // Add the same to the recipient

        allowed[_from][msg.sender] = safeSub( allowed[_from][msg.sender] , _value );

        updateBatches(_from, _to, _value);
        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    // Public getters

    function isLocked() view public returns(bool) {
        return locked;
    }

    // ERC20 specific

    function balanceOf(address _owner) view public returns(uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) view public returns(uint256) {
        return allowed[_owner][_spender];
    }

    // New Token With A Date getters

    // Address info
    function addressInfo(address _address) public view returns(
        uint _balance,
        uint _older,
        uint _newer,
        uint _batches,
        uint _firstBatch
        ) {
        if ( maxIndex[_address] == 0 ) return (0,0,0,0,0);
        return(
            balances[_address], 
            secToDays(softSub(now,batches[_address][minIndex[_address]].age)),
            secToDays(softSub(now,batches[_address][maxIndex[_address]-1].age)),
            maxIndex[_address] - minIndex[_address],
            minIndex[_address]
            );
    }

    function balanceBetween(address _address, uint _fromAge , uint _toAge) public view returns(uint _balance) {
        if (_fromAge < _toAge) { // Swap values if necessary, so order is not a problem for users
            uint _swap = _fromAge;
            _fromAge = _toAge;
            _toAge = _swap; 
            }
    	_balance = 0;
        uint batchAmount;
        uint batchAge;
    	for (uint i = minIndex[_address]; i < maxIndex[_address]; i++) {
            (batchAmount,batchAge) = getBatch(_address,i);
            if (batchAge < _toAge) break;
            if (batchAge <= _fromAge) {
	            _balance += batchAmount;
	        	}
        }
    }

    function balanceOlders(address _address,uint _age) public view returns(uint _balance) {
        _balance = 0;
        uint batchAmount;
        uint batchAge;
        for (uint i = minIndex[_address]; i < maxIndex[_address]; i++) {
            (batchAmount,batchAge) = getBatch(_address,i);
            if (batchAge < _age) break;
            if (batchAge >= _age) {
                _balance += batchAmount;
                }
        }
    }

    function balanceNewers(address _address,uint _age) public view returns(uint _balance) {
        _balance = 0;
        uint batchAmount;
        uint batchAge;
        for (uint i = minIndex[_address]; i < maxIndex[_address]; i++) {
            (batchAmount,batchAge) = getBatch(_address,i);
            if (batchAge <= _age) {
                _balance += batchAmount;
                }
        }
    }

    // Info about batches

    function getBatch(address _address , uint _batch) public view returns(uint _quant,uint _age) {
        // Retrieves info of a numered batch
        if ( batches[_address][_batch].age == 0 ) return (0,0);
        return (batches[_address][_batch].quant , secToDays(softSub(now,batches[_address][_batch].age)));
    }

    function getFirstBatch(address _address) public view returns(uint _quant,uint _age) {
        // Returns the first batch with tokens of the address
        if ( batches[_address][minIndex[_address]].age == 0 ) return (0,0);
        return (batches[_address][minIndex[_address]].quant , secToDays(softSub(now,batches[_address][minIndex[_address]].age)));
    }


    // Private internal function to register quantity and age of batches from sender and receiver
    
    function updateBatches(address _from,address _to,uint _value) private {

        // SOURCE: DISCOUNTING TOKENS
        uint count = _value;
        uint i = minIndex[_from];
         while(count > 0 && i < maxIndex[_from]) { // To iterate over the mapping. i < maxIndex is just a protection from infinite loop, that should not happen anyways
            uint _quant = batches[_from][i].quant;
            if ( _quant > 0 ) {
                if ( count >= _quant ) { // If there is more to send than the batch
                    // Empty batch and continue counting
                    count -= _quant; // First rest the batch to the count. If it's equal, loop will end
                    batches[_from][i].quant = 0; // Then empty the batch
                    minIndex[_from] = i+1;
                    } else { // If this batch is enough to send everything
                        // Empty counter and adjust the batch
                        batches[_from][i].quant -= count; // First adjust the batch, just in case anything rest
                        count = 0; // Then empty the counter and thus loop will end
                        }
            } // Closes if quantity > 0
            i++;
        } // Closes while loop

        // TARGET: COUNTING TOKENS
        // Prepare struct
        Batch memory thisBatch;
        thisBatch.initial = _value;
        thisBatch.quant = _value;
        thisBatch.age = now;
        // Assign batch and move the index
        batches[_to][maxIndex[_to]] = thisBatch;
        maxIndex[_to]++;
    }

    function secToDays(uint _lapse) pure private returns(uint _days) {
        // return _lapse / 60 / 60 / 24; // Days
        return _lapse / 60; // Minutes
    }

    function daysToSec(uint _days) pure private returns(uint _lapse) {
        // return _days * 24 * 60 * 60; // Seconds
        return _days * 24 * 60; // Minutes;
    }

}