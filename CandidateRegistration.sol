// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ElectionManager.sol";

contract CandidateRegistration {
    ElectionManager public electionManager;
    
    struct Candidate {
        uint256 id;
        string name;
        string manifesto;
        bool isApproved;
    }
    
    Candidate[] public candidates;
    mapping(address => uint256) public candidateIdByAddress;
    mapping(address => bool) public isCandidate;
    
    event CandidateRegistered(uint256 indexed candidateId, address indexed candidateAddress);
    event CandidateApproved(uint256 indexed candidateId); 
    event CandidateRegistrationReset();
    modifier onlyAdmin() {
        require(msg.sender == electionManager.admin(), "Only admin can perform this action");
        _;
    }
    
    modifier onlyInRegistrationPhase() {
        require(
            electionManager.currentState() == ElectionManager.ElectionState.Registration,
            "Registration is not active"
        );
        _;
    }
    
    constructor(address _managerAddress) {
        electionManager = ElectionManager(_managerAddress);
    }
    
    // 候选人注册
    function registerCandidate(string memory _name, string memory _manifesto) public onlyInRegistrationPhase {
        require(!isCandidate[msg.sender], "Already registered as candidate");
        
        uint256 candidateId = candidates.length;
        candidates.push(Candidate({
            id: candidateId,
            name: _name,
            manifesto: _manifesto,
            isApproved: false
        }));
        
        candidateIdByAddress[msg.sender] = candidateId;
        isCandidate[msg.sender] = true;
        
        emit CandidateRegistered(candidateId, msg.sender);
    }
    
    // 管理员批准候选人
    function approveCandidate(uint256 _candidateId) public onlyAdmin onlyInRegistrationPhase {
        require(_candidateId < candidates.length, "Invalid candidate ID");
        require(!candidates[_candidateId].isApproved, "Candidate already approved");
        
        candidates[_candidateId].isApproved = true;
        emit CandidateApproved(_candidateId);
    }
    
    // 获取所有候选人
    function getCandidatesCount() public view returns (uint256) {
        return candidates.length;
    }
    
    // 检查候选人是否有效
    function isValidCandidate(uint256 _candidateId) public view returns (bool) {
        if (_candidateId >= candidates.length) return false;
        return candidates[_candidateId].isApproved;
    }

    function reset() public {
        require(msg.sender == address(electionManager), "Only election manager can reset");
        
        // 清空候选人数组
        delete candidates;
        
        // 清空映射的逻辑与选民合约类似
        
        emit CandidateRegistrationReset();
    }

}