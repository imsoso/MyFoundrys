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

    error IlegalSigner();

    event ProposalInitiate(uint256 indexed proposalID, address to, uint256 value, bytes data, uint256 approvals);
    constructor(address[] memory _signers, uint _threshold) {
        signers = _signers;
        threshold = _threshold;
    }

    modifier onlySigner() {
        if (!isSigner(msg.sender)) {
            revert IlegalSigner();
        }
        _;
    }

    // Check if an address is an owner
    function isSigner(address addr) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function initiateProposal(address _to, uint _value, bytes memory _data) public onlySigner {
        // Create a new proposal
        uint number = proposalNumber++;
        proposals[number] = Proposal({ to: _to, value: _value, data: _data, approvals: 0 });

        emit ProposalInitiate(number, _to, _value, _data, 0);
    }
}
