// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventExample {
    // Deposit
    event Deposit(address from, uint value);
    function deposit(uint value) public {
        // 触发事件
        emit Deposit(msg.sender, value);
    }
}

pragma solidity ^0.8.0;

contract Error01Example {
    int public total;

    constructor() {}

    function divide(int divisor) public view returns (int) {
        require(divisor != 0, "divisor must not be 0");

        return total / divisor;
    }

    function addToTotal(int _value) public {
        total += _value;
        // assert
        assert(total >= _value);
    }
}

contract Error02Example {
    mapping(address => uint256) private balances;

    error InsufficientBalance();
    error InsufficientBalance2(uint, uint);

    constructor() {}

    function deposit(uint amount) public {
        if (amount <= 10) {
            revert("deposit amount must greater than 10");
        }

        balances[msg.sender] += amount;
    }

    function withdraw(uint amount) public {
        uint balance = balances[msg.sender];

        if (amount > balance) {
            revert InsufficientBalance();
        }

        balances[msg.sender] -= amount;
    }

    function withdraw2(uint amount) public {
        uint balance = balances[msg.sender];

        if (amount > balance) {
            revert InsufficientBalance2(amount, balance);
        }

        balances[msg.sender] -= amount;
    }
}

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

contract LibraryExample {
    // 使用库
    function max(uint x, uint y) public pure returns (uint) {
        return Math.max(x, y);
    }

    function min(uint x, uint y) public pure returns (uint) {
        return Math.min(x, y);
    }
}

interface ICounter {
    function increment() external;
}

contract InterfaceExample {
    function incrementCounter(address _counter) external {
        ICounter(_counter).increment();
    }
}

/*
这段 Solidity 代码定义了一个名为InterfaceExample的智能合约，使用OpenZeppelin的IERC20接口进行转账。

请补充完整constructor，将tokenAddr强制类型转换为IERC20接口，并赋值给token
请补充完整sendReward函数，利用IERC20接口的transfer方法将amount数量代币从合约的余额中转移给接收者
*/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract InterfaceExample2 {
    IERC20 immutable token;

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    function sendReward(address receiver, uint amount) public {
        token.transfer(receiver, amount);
    }
}
