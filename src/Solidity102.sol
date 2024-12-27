// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ABIEncoder {
    function encodeUint(uint256 value) public pure returns (bytes memory) {
        return abi.encode(value);
    }

    function encodeMultiple(uint num, string memory text) public pure returns (bytes memory) {
        return abi.encode(num, text);
    }
}

contract ABIDecoder {
    function decodeUint(bytes memory data) public pure returns (uint) {
        return abi.decode(data, (uint));
    }

    function decodeMultiple(bytes memory data) public pure returns (uint, string memory) {
        return abi.decode(data, (uint, string));
    }
}

contract FunctionSelector {
    uint256 private storedValue;

    function getValue() public view returns (uint) {
        return storedValue;
    }

    function setValue(uint value) public {
        storedValue = value;
    }

    // 返回 getValue() 函数的选择器
    function getFunctionSelector1() public pure returns (bytes4) {
        return this.getValue.selector;
    }

    // 返回 setValue(uint256) 函数的选择器
    function getFunctionSelector2() public pure returns (bytes4) {
        return this.setValue.selector;
    }
}

contract DataStorage {
    string private data;

    function setData(string memory newData) public {
        data = newData;
    }

    function getData() public view returns (string memory) {
        return data;
    }
}

contract DataConsumer {
    address private dataStorageAddress;

    constructor(address _dataStorageAddress) {
        dataStorageAddress = _dataStorageAddress;
    }

    function getDataByABI() public returns (string memory) {
        // payload
        bytes4 selector = bytes4(keccak256('getData()'));
        bytes memory payload = abi.encode(selector);
        (bool success, bytes memory data) = dataStorageAddress.call(payload);
        require(success, 'call function failed');
        return abi.decode(data, (string));
    }
    function setDataByABI1(string calldata newData) public returns (bool) {
        // playload
        bytes memory payload = abi.encodeWithSignature('setData(string)', newData);
        (bool success, ) = dataStorageAddress.call(payload);

        return success;
    }

    function setDataByABI2(string calldata newData) public returns (bool) {
        // selector
        bytes4 selector = bytes4(keccak256('setData(string)'));
        // playload
        bytes memory payload = abi.encodeWithSelector(selector, newData);

        (bool success, ) = dataStorageAddress.call(payload);

        return success;
    }

    function setDataByABI3(string calldata newData) public returns (bool) {
        // playload
        bytes memory payload = abi.encodeCall(DataStorage.setData, newData);
        (bool success, ) = dataStorageAddress.call(payload);
        return success;
    }
}

contract Callee {
    function getData() public pure returns (uint256) {
        return 42;
    }
}

contract Caller {
    function callGetData(address callee) public view returns (uint256 data) {
        // call by staticcall
        bytes memory payload = abi.encodeWithSignature('getData()');

        (bool success, bytes memory result) = callee.staticcall(payload);
        require(success, 'staticcall function failed');

        data = abi.decode(result, (uint));
        return data;
    }
}

contract Caller2 {
    function sendEther(address to, uint256 value) public returns (bool) {
        // 使用 call 发送 ether
        (bool success, ) = to.call{ value: value }('');
        require(success, 'sendEther failed');
        return success;
    }

    receive() external payable {}
}

contract Callee3 {
    uint256 value;

    function getValue() public view returns (uint256) {
        return value;
    }

    function setValue(uint256 value_) public payable {
        require(msg.value > 0);
        value = value_;
    }
}

contract Caller3 {
    function callSetValue(address callee, uint256 value) public returns (bool) {
        // call setValue()
        bytes memory dataToCall = abi.encodeWithSignature('setValue(uint256)', value);
        (bool success, ) = callee.call{ value: 1 ether }(dataToCall);
        require(success, 'call function failed');
        return success;
    }
}

contract Callee4 {
    uint256 public value;

    function setValue(uint256 _newValue) public {
        value = _newValue;
    }
}

contract Caller4 {
    uint256 public value;

    function delegateSetValue(address callee, uint256 _newValue) public {
        // delegatecall setValue()
        bytes memory dataTocall = abi.encodeWithSignature('setValue(uint256)', _newValue);
        (bool success, ) = callee.delegatecall(dataTocall);
        require(success, 'delegate call failed');
    }
}

contract ChildContract {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }
}

contract Factory {
    function createChild(uint256 _value) public returns (address) {
        // create contract
        ChildContract child = new ChildContract(_value);
        return address(child);
    }
}

contract ChildContract2 {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }
}

contract Factory2 {
    function createChild(bytes32 _salt, uint256 _value) public returns (address) {
        // create contract using crteate2
        ChildContract child = new ChildContract{ salt: _salt }(_value);
        return address(child);
    }
}

/* depercated 
contract Destroy {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function killSelf(address receiver) public {
        require(msg.sender == owner, 'Only owner can call this function');
        // 销毁自身并把 ETH 发功给 receiver
        address payable addr = payable(address(receiver));

        selfdestruct(addr);
    }
}
contract Child {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function destroy() public {
        // 销毁自身并把 ETH 发送给调用者
        address payable addr = payable(address(msg.sender));

        selfdestruct(addr);
    }
}

contract Parent {
    constructor() {}

    function createAndDestroy() public returns (address) {
        // 创建子合约
        Child child = new Child('Hello, world!');
        // 立即销毁子合约
        child.destroy();
        // 返回子合约地址
        return address(child);
    }
}
*/

contract Implementation {
    address public implementation; // 没用上，但是这里占位是为了防止存储冲突
    uint256 public counter;

    function addCounter() public {
        counter += 1;
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}

contract BaseProxy {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        // delegate to implementation contract
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);

        if (!success) {
            // If the delegatecall failed, revert the transaction with the returned data
            assembly {
                revert(add(data, 32), mload(data))
            }
        }

        // If the delegatecall succeeded, return the data
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}

/*
在这个挑战中，提供了两个合约：Secret 和 ReadSlot。Secret 合约包含一个私有的结构体 SecretStruct，用来保存一些信息，而 ReadSlot 则继承了这一合约。

你的任务是完成 ReadSlot 合约中的 readSecretB 函数，借助内联汇编，实现对存储在合约内的“秘密地址（secret.b）”的读取。

这个具体挑战涉及对 Solidity 存储槽的理解。聪明的开发者将能够通过对合约存储的深刻理解，来揭开隐藏在 Secret 合约中的秘密数据。
*/
contract Secret {
    struct SecretStruct {
        uint16 a;
        address b;
    }

    SecretStruct private secret;

    constructor(uint16 a, address b) {
        secret = SecretStruct(a, b);
    }
}

/*
1. uint16 a的存储方式问题
结构体SecretStruct中的uint16 a（16位）不会单独占用整个slot 0，它会打包进slot 0的前两个字节。
address b紧随其后，存储在slot 0的剩余空间，而不会直接分配到slot 1。
这意味着直接使用slot 1读取address b是错误的。
存储布局解析：
secret.a（uint16）占 slot 0的前两个字节。
secret.b（address）紧随其后，占slot 0的低位20个字节。
实际情况：slot 0 = [ 0x0000...0000 || secret.a || secret.b ]（高位未用部分填充0）。

*/
contract ReadSlot is Secret {
    constructor(uint16 a, address b) Secret(a, b) {}

    function readSecretB() public view returns (address) {
        uint256 data;
        assembly {
            data := sload(0)
        }
        return address(uint160(data >> 16));
    }
}

/*题目#10
使用瞬态存储实现防止重入合约
  
补充完整以下合约，要求：

声明一个瞬态存储变量 locked
补充完整 nonReentrant 修饰器，实现防止重入功能
*/
contract TReentrant {
    mapping(address => bool) claimed;
    // 声明瞬态存储变量 locked
    bool transient  locked;
    modifier nonReentrant() {
        require(!locked, 'Reentrancy attempt');
        locked = true;
        _;
        // 补充剩余代码
    }

    function claim() public nonReentrant {
        require(address(this).balance >= 1 ether);

        require(!claimed[msg.sender], 'Already claimed');

        (bool success, ) = msg.sender.call{ value: 1 ether }('');

        require(success, 'Claim failed');

        claimed[msg.sender] = true;
    }
}
