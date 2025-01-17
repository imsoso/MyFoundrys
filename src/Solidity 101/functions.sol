// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ConstructorExample {
    // owner
    address public owner;
    // constructor
    constructor() {
        owner = msg.sender;
    }
}

contract Multiplier {
    function multiplyByTwo(uint number) public pure returns (uint) {
        return number * 2;
    }
}

contract FucStateVariability {
    function pureFunc(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    function viewFunc(uint a, uint b) public view returns (uint) {
        return a + b + block.number;
    }
}

contract Visibility {
    uint private privateVar = 10;
    uint internal internalVar = 20;
    uint public publicVar = 30;

    function getPrivateVar() public view returns (uint) {
        return privateVar;
    }

    function getInternalVar() public view returns (uint) {
        return internalVar;
    }

    function externalFunction() external view returns (uint) {
        return publicVar;
    }

    function getPublicVar() public view returns (uint) {
        return this.externalFunction();
    }
}

/*
在 Solidity 中，正确的数据存储位置不仅关系到合约的执行效率，还直接影响交易成本（gas）。storage、memory和calldata是用以指定数据存储位置的关键词，它们分别用于持久存储、临时存储和外部函数调用参数。

任务描述:
以下是部分完成的智能合约，其中包括一个用于存储整数的数组以及三个函数。这些函数分别用于：

添加一系列新元素到数组中
返回从指定索引开始的数字序列
修改数组中的所有元素，增加特定值
在合约代码中的三个空白处（____）填入正确的关键词（calldata、memory或storage），以确保合约可以正常编译并通过测试。
*/
contract DataLocation {
    uint[] private numbers;

    // 添加一系列新元素到数组中
    function addNumbers(uint[] memory _numbers) public {
        for (uint i = 0; i < _numbers.length; i++) {
            numbers.push(_numbers[i]);
        }
    }

    // 返回从指定索引开始的数字序列
    function getNumbers(uint start, uint count) public view returns (uint[] memory result) {
        result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = numbers[start + i];
        }
    }

    // 修改数组中的所有元素，增加特定值
    function increaseNumbers(uint value) public {
        uint[] storage storedNumbers = numbers;
        for (uint i = 0; i < storedNumbers.length; i++) {
            storedNumbers[i] += value;
        }
    }
}

contract ModifierExample {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, 'Only owner');
        _;
    }

    function withdraw() public isOwner {
        // 函数体可以留空
    }
}

abstract contract Vehicle {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    // 抽象函数，要求继承的子类实现具体功能
    function move() public pure virtual returns (string memory);
}

contract Car is Vehicle {
    // 使用构造函数来初始化基类的数据
    constructor(string memory _name) Vehicle(_name) {}

    // 重载父类的抽象方法
    function move() public pure override returns (string memory) {
        return 'Car drives on the road';
    }
}

/*
在Solidity中，receive和fallback函数是两种特殊类型的函数，它们都没有名字、没有参数，也不能返回任何值。这两个函数的设计目的是为了让智能合约能够直接接收以太币（Ether）并进行处理。
要求：

编写receive函数，使totalReceived增加接收到的 Ether 值
编写fallback函数，使totalReceived增加接收到的 Ether 值
*/
contract Callback {
    address public owner;
    uint public totalReceived;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, 'Caller is not the owner');
        _;
    }

    receive() external payable isOwner {
        totalReceived += msg.value;
    }
    fallback() external payable isOwner {
        totalReceived += msg.value;
    }

    // 允许合约拥有者提款所有收到的以太
    function withdraw() public isOwner {
        payable(owner).transfer(address(this).balance);
    }
}
