// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MultiSignWallet {
    // List of multi-signature owners
    address[] public signers;
    // Signature threshold
    uint public threshold;

    uint256 public proposalNumber;

    struct Proposal {
        address to;
        uint value;
        bytes data;
        uint approvals;
    }
    mapping(uint256 => Proposal) public proposals;

    event ProposalInitiate(uint256 indexed proposalID, address to, uint256 value, bytes data, uint256 approvals);
    constructor(address[] memory _signers, uint _threshold) {
        signers = _signers;
        threshold = _threshold;
    }

    function initiateProposal(address _to, uint _value, bytes memory _data) public {
        // Create a new proposal
        uint number = proposalNumber++;
        proposals[number] = Proposal({ to: _to, value: _value, data: _data, approvals: 0 });

        emit ProposalInitiate(number, _to, _value, _data, 0);
    }
}
