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
