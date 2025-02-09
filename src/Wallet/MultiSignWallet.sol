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
    mapping(uint256 => mapping(address => bool)) public proposalApprovals;
    mapping(uint256 => bool) public executedProposals;

    error IlegalSigner();
    error NotEnoughApprovals();
    error ExecutionFailed();
    error AlreadyApproved();
    error AlreadyExecuted();

    event ProposalInitiate(uint256 indexed proposalID, address to, uint256 value, bytes data);
    event ProposalApproved(uint256 indexed proposalID, address signer);

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

    function initiateProposal(address to, uint value, bytes memory data) public onlySigner {
        // Create a new proposal
        uint number = proposalNumber++;
        Proposal storage proposal = proposals[number];
        proposal.to = to;
        proposal.value = value;
        proposal.data = data;

        emit ProposalInitiate(number, to, value, data);
    }

    function approveProposal(uint256 proposalID) public {
        Proposal storage proposal = proposals[proposalID];
        if (proposalApprovals[proposalID][msg.sender] == true) {
            revert AlreadyApproved();
        }

        proposal.approvals++;
        // msg sender approve the proposal
        proposalApprovals[proposalID][msg.sender] = true;

        emit ProposalApproved(proposalID, msg.sender);
    }

    function executeProposal(uint256 proposalID) public {
        Proposal storage proposal = proposals[proposalID];

        if (executedProposals[proposalID] == true) {
            revert AlreadyExecuted();
        }
        if (proposal.approvals >= threshold) {
            // Execute the transaction
            (bool success, ) = proposal.to.call{ value: proposal.value }(proposal.data);
            if (!success) revert ExecutionFailed();
        } else {
            revert NotEnoughApprovals();
        }
    }
}
