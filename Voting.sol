// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ElectionManager.sol";
import "./VoterRegistration.sol";
import "./CandidateRegistration.sol";

contract Voting {
    ElectionManager public electionManager;
    VoterRegistration public voterContract;
    CandidateRegistration public candidateContract;
    
    // 存储加密的投票
    mapping(address => bytes) public encryptedVotes;
    
    // 投票计数器 (candidateId => voteCount)
    // 注意：实际上在隐私保护的选举中，票数不应该在链上直接可见
    mapping(uint256 => uint256) private votesReceived;
    
    event VoteCast(address indexed voter, bytes encryptedVote);
    event VotingReset();
    modifier onlyInVotingPhase() {
        require(
            electionManager.currentState() == ElectionManager.ElectionState.Voting,
            "Voting is not active"
        );
        _;
    }
    
    constructor(
        address _managerAddress, 
        address _voterContractAddress, 
        address _candidateContractAddress
    ) {
        electionManager = ElectionManager(_managerAddress);
        voterContract = VoterRegistration(_voterContractAddress);
        candidateContract = CandidateRegistration(_candidateContractAddress);
    }
    
    // 投票功能（使用加密投票保护隐私）
    function castVote(bytes memory _encryptedVote, uint256 _candidateId) public onlyInVotingPhase {
        // 验证投票人资格
        require(voterContract.verifyVoter(msg.sender), "Not eligible to vote");
        
        // 验证候选人有效性
        require(candidateContract.isValidCandidate(_candidateId), "Invalid candidate");
        
        // 记录加密投票
        encryptedVotes[msg.sender] = _encryptedVote;
        
        // 更新投票计数（在实际的隐私保护系统中，这一步应该在链下进行或使用零知识证明）
        votesReceived[_candidateId]++;
        
        // 标记该投票人已投票
        voterContract.markVoted(msg.sender);
        
        emit VoteCast(msg.sender, _encryptedVote);
    }
    
    // 在计票阶段获取候选人的票数（仅由结果合约调用）
    function getVotesForCandidate(uint256 _candidateId) public view returns (uint256) {
        require(
            msg.sender == electionManager.resultContract() || 
            msg.sender == electionManager.admin(),
            "Only authorized contracts or admin can access vote counts"
        );
        
        return votesReceived[_candidateId];
    }

    function reset() public {
        require(msg.sender == address(electionManager), "Only election manager can reset");
        
        // 清空投票数据的逻辑
        // 注意：同样无法完全清除所有映射数据
        
        emit VotingReset();
    }


}