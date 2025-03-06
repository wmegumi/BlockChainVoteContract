// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IResettable {
    function reset() external;
}

contract ElectionManager {
    // 选举状态枚举
    enum ElectionState {
        Registration,
        Voting,
        Tallying,
        Completed,
        Initialized
    }
    
    ElectionState public currentState;
    address public admin;
    
    // 其他模块的地址
    address public voterRegistrationContract;
    address public candidateRegistrationContract;
    address public votingContract;
    address public resultContract;
    address public auditContract;
    
    // 事件声明
    event StateChanged(ElectionState previousState, ElectionState newState);
    event ElectionReset();
    event DataCleared();
    
    constructor() {
        admin = msg.sender;
        currentState = ElectionState.Initialized;
    }
    
    // 修饰符：只有管理员可以调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    // 修饰符：检查当前状态
    modifier inState(ElectionState state) {
        require(currentState == state, "Invalid state for this operation");
        _;
    }
    
    // 启动选举流程 - 进入注册期
    function startElection() public onlyAdmin inState(ElectionState.Initialized) {
        currentState = ElectionState.Registration;
        emit StateChanged(ElectionState.Initialized, ElectionState.Registration);
    }
    
    // 从注册期手动转换到投票期
    function startVotingPhase() public onlyAdmin inState(ElectionState.Registration) {
        currentState = ElectionState.Voting;
        emit StateChanged(ElectionState.Registration, ElectionState.Voting);
    }
    
    // 从投票期手动转换到计票期
    function startTallyingPhase() public onlyAdmin inState(ElectionState.Voting) {
        currentState = ElectionState.Tallying;
        emit StateChanged(ElectionState.Voting, ElectionState.Tallying);
    }
    
    // 从计票期手动转换到完成期
    function completeElection() public onlyAdmin inState(ElectionState.Tallying) {
        currentState = ElectionState.Completed;
        emit StateChanged(ElectionState.Tallying, ElectionState.Completed);
    }
    
    // 重置选举（仅在完成状态下可调用）- 修改版，清空所有数据
    function resetElection() public onlyAdmin inState(ElectionState.Completed) {
        // 重置本合约的状态
        currentState = ElectionState.Initialized;
        
        // 调用各子合约的重置函数
        if (voterRegistrationContract != address(0)) {
            try IResettable(voterRegistrationContract).reset() {
                // 成功重置
            } catch {
                // 如果子合约没有实现reset函数或执行失败，继续进行其他重置
            }
        }
        
        if (candidateRegistrationContract != address(0)) {
            try IResettable(candidateRegistrationContract).reset() {
                // 成功重置
            } catch {
                // 忽略错误继续执行
            }
        }
        
        if (votingContract != address(0)) {
            try IResettable(votingContract).reset() {
                // 成功重置
            } catch {
                // 忽略错误继续执行
            }
        }
        
        if (resultContract != address(0)) {
            try IResettable(resultContract).reset() {
                // 成功重置
            } catch {
                // 忽略错误继续执行
            }
        }
        
        if (auditContract != address(0)) {
            try IResettable(auditContract).reset() {
                // 成功重置
            } catch {
                // 忽略错误继续执行
            }
        }
        
        emit ElectionReset();
        emit DataCleared();
    }
    
    // 设置各模块合约地址
    function setContracts(
        address _voter,
        address _candidate,
        address _voting,
        address _result,
        address _audit
    ) public onlyAdmin {
        voterRegistrationContract = _voter;
        candidateRegistrationContract = _candidate;
        votingContract = _voting;
        resultContract = _result;
        auditContract = _audit;
    }
}