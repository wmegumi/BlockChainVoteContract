// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ElectionManager.sol";
import "./CandidateRegistration.sol";
import "./Voting.sol";

contract ElectionResult {
    ElectionManager public electionManager;
    CandidateRegistration public candidateContract;
    Voting public votingContract;
    
    uint256 public winningCandidateId;
    bool public resultsDeclared;
    
    struct Result {
        uint256 candidateId;
        uint256 voteCount;
    }
    
    Result[] public finalResults;
    
    event ResultsDeclared(uint256 indexed winningCandidateId, uint256 voteCount);
    event ResultsReset();
    modifier onlyInTallyingPhase() {
        require(
            electionManager.currentState() == ElectionManager.ElectionState.Tallying,
            "Not in tallying phase"
        );
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == electionManager.admin(), "Only admin can perform this action");
        _;
    }
    
    constructor(
        address _managerAddress, 
        address _candidateContractAddress, 
        address _votingContractAddress
    ) {
        electionManager = ElectionManager(_managerAddress);
        candidateContract = CandidateRegistration(_candidateContractAddress);
        votingContract = Voting(_votingContractAddress);
    }
    
    // 计算和发布选举结果
    function tabulateResults() public onlyAdmin onlyInTallyingPhase {
        require(!resultsDeclared, "Results already declared");
        
        uint256 candidatesCount = candidateContract.getCandidatesCount();
        uint256 highestVotes = 0;
        
        for (uint256 i = 0; i < candidatesCount; i++) {
            if (candidateContract.isValidCandidate(i)) {
                uint256 voteCount = votingContract.getVotesForCandidate(i);
                
                finalResults.push(Result({
                    candidateId: i,
                    voteCount: voteCount
                }));
                
                if (voteCount > highestVotes) {
                    highestVotes = voteCount;
                    winningCandidateId = i;
                }
            }
        }
        
        resultsDeclared = true;
        emit ResultsDeclared(winningCandidateId, highestVotes);
    }
    
    // 获取最终结果
    function getResults() public view returns (Result[] memory) {
        require(resultsDeclared, "Results not yet declared");
        return finalResults;
    }
    
    // 获取获胜者信息
    function getWinner() public view returns (uint256) {
        require(resultsDeclared, "Results not yet declared");
        return winningCandidateId;
    }
    function reset() public {
        require(msg.sender == address(electionManager), "Only election manager can reset");
        
        // 清空结果数据
        delete finalResults;
        winningCandidateId = 0;
        resultsDeclared = false;
        
        emit ResultsReset();
    }

}