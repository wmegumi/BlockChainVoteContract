// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ElectionManager.sol";

contract VoterRegistration {
    ElectionManager public electionManager;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        bytes32 voterHash; // 存储选民数据的哈希值，保护隐私
    }
    
    mapping(address => Voter) public voters;
    uint256 public totalVoters;
    
    event VoterRegistered(address indexed voterAddress);
    event VoterRegistrationReset();
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
    
    // 选民注册函数
    function register(bytes32 _voterDataHash) public onlyInRegistrationPhase {
        require(!voters[msg.sender].isRegistered, "Voter already registered");
        
        voters[msg.sender] = Voter({
            isRegistered: true,
            hasVoted: false,
            voterHash: _voterDataHash
        });
        
        totalVoters++;
        emit VoterRegistered(msg.sender);
    }
    
    // 验证选民资格
    function verifyVoter(address _voter) public view returns (bool) {
        return voters[_voter].isRegistered && !voters[_voter].hasVoted;
    }
    
    // 标记选民已投票（仅由投票合约调用）
    function markVoted(address _voter) public {
        require(msg.sender == electionManager.votingContract(), "Only voting contract can mark voters");
        require(voters[_voter].isRegistered, "Voter not registered");
        require(!voters[_voter].hasVoted, "Voter has already voted");
        
        voters[_voter].hasVoted = true;
    }

    function reset() public {
        require(msg.sender == address(electionManager), "Only election manager can reset");
        
        // 清空所有选民数据
        totalVoters = 0;
        
        // 注意：由于无法删除映射中的所有键值对，我们在下一次选举时会检查 isRegistered 状态
        // 这是一个权衡方案，但更彻底的解决方案是重新部署合约
        
        emit VoterRegistrationReset();
    }


}