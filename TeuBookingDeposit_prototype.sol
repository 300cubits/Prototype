pragma solidity 0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev revert()s if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * Math operations with safety checks
 */
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b > 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev ERC20 interface with allowances. 
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public {

    //  To change the approve amount you first have to reduce the addresses
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



/**
 * @title TeuToken
 * @dev The main TEU token contract
 * 
 */
 
contract TeuToken is StandardToken, Ownable{
  string public name = "20-footEqvUnit";
  string public symbol = "TEU";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() public {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

  /**
   * @dev Allows the owner to burn the token
   * @param _value number of tokens to be burned.
   */
  function burn(uint _value) onlyOwner public {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}


/**
 * @title teuBookingDeposit 
 * @dev TEU Booking Deposit: A smart contract governing the entitlement of TEU token of two parties for a container shipping booking 
  */
contract TeuBookingDeposit is Ownable {
    event TokenTransferredToBooking(string indexed fromClientId, uint256 restrictedAmount, uint256 amount);
    event TokenReturnedToClient(string indexed toClientId, uint256 restrictedAmount, uint256 amount);
    event TokenTransferredToClient(string indexed fromClientId, string indexed toClientId, uint256 restrictedAmount, uint256 amount);
    
    using SafeMath for uint256;

    mapping(string => uint256) private clientTokenBalanceOf;
    uint256 public totalClientToken;

    mapping(string => uint256) private restrictedTokenBalanceOf;
    uint256 public totalRestrictedToken;
    
    mapping(string  => uint256) private clientTokenBookingBalanceOf;
    uint256 public totalBookingClientToken;

    mapping(string => uint256) private restrictedTokenBookingBalanceOf;
    uint256 public totalBookingRestrictedToken;
    
    mapping(string => address) private clientTokenWalletOf;
    
    TeuToken    private token;
    
// functions for client shadow wallet management
    function setWalletToClientAccount(string _clientId, address _wallet) onlyOwner public {
        clientTokenWalletOf[_clientId] = _wallet;
    }
    
    function changeClientTokenWallet(string _clientId, address _newWallet) public
    {
        require(clientTokenWalletOf[_clientId] == msg.sender);
        clientTokenWalletOf[_clientId] = _newWallet;
    }

    function receiveTokenByClientAccount(string _clientId, uint256 _tokenAmount, address _transferFrom) public {
        require(_tokenAmount > 0);

        clientTokenBalanceOf[_clientId] = clientTokenBalanceOf[_clientId].add256(_tokenAmount);
        totalClientToken = totalClientToken.add256(_tokenAmount);

        token.transferFrom(_transferFrom, this, _tokenAmount);            
    }
    
    function withdrawTokenFromClientAccount(string _fromClientId, address _to, uint256 _tokenAmount) public {
        require(_tokenAmount > 0);
        require(clientTokenWalletOf[_fromClientId] == msg.sender);

        clientTokenBalanceOf[_fromClientId] = clientTokenBalanceOf[_fromClientId].sub256(_tokenAmount);
        totalClientToken = totalClientToken.sub256(_tokenAmount);

        token.transfer(_to, _tokenAmount);        
    }

    // functions for restricted token management
    function allocateRestrictedTokenTo(string _clientId, uint256 _tokenAmount) onlyOwner public {
        require(_tokenAmount <= token.balanceOf(this).sub256(totalBookingClientToken).sub256(totalClientToken).sub256(totalRestrictedToken).add256(restrictedTokenBalanceOf[_clientId]));

        totalRestrictedToken = totalRestrictedToken.sub256(restrictedTokenBalanceOf[_clientId]).add256(_tokenAmount);
        restrictedTokenBalanceOf[_clientId] = _tokenAmount;
    }
    
    function withdrawUnallocatedRestrictedToken(uint256 _tokenAmount) onlyOwner public {
        require(_tokenAmount <= token.balanceOf(this).sub256(totalBookingClientToken).sub256(totalClientToken).sub256(totalRestrictedToken));

        token.transfer(msg.sender, _tokenAmount);
    } 

// functions for transferring token to booking    
    function unrestrictedTokenTransferToBooking(string _fromClientId, uint256 _tokenAmount) onlyOwner private {
        require(clientTokenBalanceOf[_fromClientId] >= _tokenAmount);

        clientTokenBalanceOf[_fromClientId] = clientTokenBalanceOf[_fromClientId].sub256(_tokenAmount);
        clientTokenBookingBalanceOf[_fromClientId] = clientTokenBookingBalanceOf[_fromClientId].add256(_tokenAmount);

        totalBookingClientToken = totalBookingClientToken.add256(_tokenAmount);
        totalClientToken = totalClientToken.sub256(_tokenAmount);
    }       

    
    function restrictedTokenTransferToBooking(string _fromClientId, uint256 _tokenAmount) onlyOwner private {
        require(restrictedTokenBalanceOf[_fromClientId] >= _tokenAmount);

        restrictedTokenBalanceOf[_fromClientId] = restrictedTokenBalanceOf[_fromClientId].sub256(_tokenAmount);
        restrictedTokenBookingBalanceOf[_fromClientId] = restrictedTokenBookingBalanceOf[_fromClientId].add256(_tokenAmount);
        
        totalBookingRestrictedToken = totalBookingRestrictedToken.add256(_tokenAmount);
        totalRestrictedToken = totalRestrictedToken.sub256(_tokenAmount);
    }        


    function tokenTransferToBooking(string _fromClientId, uint256 _tokenAmount, uint256 _restrictedTokenAmount) onlyOwner public {
        if (_tokenAmount > 0)
            unrestrictedTokenTransferToBooking(_fromClientId, _tokenAmount);
            
        if (_restrictedTokenAmount > 0)
            restrictedTokenTransferToBooking(_fromClientId, _restrictedTokenAmount);

        TokenTransferredToBooking(_fromClientId, _restrictedTokenAmount, _tokenAmount);
    }       
    
 
// functions for returning tokens
     function returnRestrictedToken(string _toClientId, uint256 _tokenAmount) onlyOwner private {
        require(restrictedTokenBookingBalanceOf[_toClientId] >= _tokenAmount);

        restrictedTokenBookingBalanceOf[_toClientId] = restrictedTokenBookingBalanceOf[_toClientId].sub256(_tokenAmount);
        restrictedTokenBalanceOf[_toClientId] = restrictedTokenBalanceOf[_toClientId].add256(_tokenAmount);
        
        totalBookingRestrictedToken = totalBookingRestrictedToken.sub256(_tokenAmount);
        totalRestrictedToken = totalRestrictedToken.add256(_tokenAmount);
    }        
   
    function returnCleintToken(string _toClientId, uint256 _tokenAmount) onlyOwner private {
        require(clientTokenBookingBalanceOf[_toClientId] >= _tokenAmount);

        clientTokenBookingBalanceOf[_toClientId] = clientTokenBookingBalanceOf[_toClientId].sub256(_tokenAmount);
        clientTokenBalanceOf[_toClientId] = clientTokenBalanceOf[_toClientId].add256(_tokenAmount);
        
        totalBookingClientToken = totalBookingClientToken.sub256(_tokenAmount);
        totalClientToken = totalClientToken.add256(_tokenAmount);
    }  
    
    function returnToken(string _toClientId, uint256 _clientTokenAmount, uint256 _restrctedTokenAmount) onlyOwner public {
        if (_clientTokenAmount > 0)
            returnCleintToken(_toClientId, _clientTokenAmount);
        
        if (_restrctedTokenAmount > 0)
            returnRestrictedToken(_toClientId, _restrctedTokenAmount);
        
        TokenReturnedToClient(_toClientId, _restrctedTokenAmount, _clientTokenAmount);
    }      
   
    function tansferClientToken(string _fromClientId, string _toClientId, uint256 _tokenAmount) onlyOwner private {
        require(clientTokenBookingBalanceOf[_fromClientId] >= _tokenAmount);

        clientTokenBookingBalanceOf[_fromClientId] = clientTokenBookingBalanceOf[_fromClientId].sub256(_tokenAmount);
        clientTokenBalanceOf[_toClientId] = clientTokenBalanceOf[_toClientId].add256(_tokenAmount);
        
        totalBookingClientToken = totalBookingClientToken.sub256(_tokenAmount);
        totalClientToken = totalClientToken.add256(_tokenAmount);
    }        

    function transferRestrictedToken(string _fromClientId, string _toClientId, uint256 _tokenAmount) onlyOwner private {
        require(restrictedTokenBookingBalanceOf[_fromClientId] >= _tokenAmount);

        restrictedTokenBookingBalanceOf[_fromClientId] = restrictedTokenBookingBalanceOf[_fromClientId].sub256(_tokenAmount);
        clientTokenBalanceOf[_toClientId] = clientTokenBalanceOf[_toClientId].add256(_tokenAmount);
        
        totalBookingRestrictedToken = totalBookingRestrictedToken.sub256(_tokenAmount);
        totalClientToken = totalClientToken.add256(_tokenAmount);
    }        

    function tansferToken(string _fromClientId, string _toClientId, uint256 _clientTokenAmount, uint256 _restrictedTokenAmount) onlyOwner public {
        if (_clientTokenAmount > 0)
            tansferClientToken(_fromClientId, _toClientId, _clientTokenAmount);
        if (_restrictedTokenAmount > 0)
            transferRestrictedToken(_fromClientId, _toClientId, _restrictedTokenAmount);            
        
        TokenTransferredToClient(_fromClientId, _toClientId, _restrictedTokenAmount, _clientTokenAmount);
    }   

// function for Admin
    function setToken(address _token) public onlyOwner {
        require (token == address(0));
        token = TeuToken(_token);
    }
    
// functions for Retrieving information


    function getClientTokenBalance(string _clientId) constant public returns (uint256) {
        return clientTokenBalanceOf[_clientId];
    }

    function getRestrictedTokenBalance(string _clientId) constant public returns (uint256) {
        return restrictedTokenBalanceOf[_clientId];
    }

    function getClientTokenBookingBalance(string _clientId) constant public returns (uint256) {
        return clientTokenBookingBalanceOf[_clientId];
    }

    function getRestrictedTokenBookingBalance(string _clientId) constant public returns (uint256) {
        return restrictedTokenBookingBalanceOf[_clientId];
    }

}

