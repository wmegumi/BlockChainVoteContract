部署：
首先部署 ElectionManager
然后部署 VoterRegistration 和 CandidateRegistration（_managerAddress: ElectionManager合约的部署地址）
接着部署 Voting（_managerAddress: ElectionManager合约的部署地址，_voterContractAddress: VoterRegistration合约的部署地址，_candidateContractAddress: CandidateRegistration合约的部署地址）
然后部署 ElectionResult（_managerAddress: ElectionManager合约的部署地址，_candidateContractAddress: CandidateRegistration合约的部署地址，_votingContractAddress: Voting合约的部署地址）
最后部署 AuditVerification（_managerAddress: ElectionManager合约的部署地址，_voterAddress: VoterRegistration合约的部署地址，_candidateAddress: CandidateRegistration合约的部署地址，_votingAddress: Voting合约的部署地址，_resultAddress: ElectionResult合约的部署地址）
调用 ElectionManager 的 setContracts 方法，注册所有合约地址

状态转换的流程:
初始状态为 Initialized
管理员调用 startElection() 进入注册期
当注册阶段完成时，管理员调用 startVotingPhase() 进入投票期
当投票阶段完成时，管理员调用 startTallyingPhase() 进入计票期
当计票阶段完成时，管理员调用 completeElection() 进入完成期
选举完成后，管理员可以调用 resetElection() 重置系统，准备下一次选举
实际操作：

1.管理员调用 startVotingPhase()进入注册期

2.用户注册voter，用户调用register填写_voterDataHash（选民个人信息哈希值）如
async function generateVoterHash(voterInfo) {
  // 选民信息对象
  const voter = {
    name: "张三",
    idNumber: "110101199001011234", // 身份证号
    dateOfBirth: "1990-01-01",
    additionalData: "其他验证信息"
  };
  
  // 转换为JSON字符串
  const voterString = JSON.stringify(voter);
  
  // 使用Web3.js或ethers.js计算keccak256哈希
  // 这里以ethers.js为例
  const voterHash = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes(voterString)
  );
  
  return voterHash;
}
可以使用0x7d5a99f603f231d53a4f39d1521f98d2e8bb279cf29bebfd0687dc98458e7f89 进行测试

3.用户注册候选人：
用户调用registerCandidate填写_name姓名、_manifesto信息
管理员调用approveCandidate填写候选人id，可通过mapping查看信息id为候选人在数组中的下标，来通过候选人验证申请。

4.管理员调用startVotingPhase() 进入投票期

5.投票人调用castVote	输入_encryptedVote加密投票信息的字节数组，可用于后面的验证和_candidateId候选人id投票。
_encryptedVote可以考虑如下获得
async function prepareVote(candidateId) {
  // 使用公钥加密投票数据
  const voteData = {
    candidateId: candidateId,
    timestamp: Date.now(),
    randomNonce: ethers.utils.randomBytes(16)  // 防止重放攻击
  };
  
  // 序列化并加密（实际项目中可能使用更复杂的加密方案）
  const serializedVote = JSON.stringify(voteData);
  const encryptedVote = await encryptWithPublicKey(serializedVote, electionPublicKey);
  
  return ethers.utils.arrayify(encryptedVote);
}
测试可使用示例
0x8a7c32e95c9c47b5d3f42476b8d535d71588ffe512c9c4a1b89b7a277c9753b2ef6a89a451b0d32d6a946f04626d4c230b7d840519256c2b6c8a4fbef21b4f3def33841a83135e4a3d452bc03e903807bf9b4f4b81fb94e0342e4ee6f8f4fda0

6.管理员调用startTallyingPhase() 进入计票期

7.管理员调用tabulateResults() 得出投票结果。使用getResults，getWinner等获得结果信息

8.管理员调用 completeElection() 进入完成期

9.用户可使用fileComplaint（）填写投诉信息提交投诉

10.管理员使用complants数组查看投诉，使用resolveComplaint填写_complaintId投诉id,和_resolution解决方案，填写投诉解答。

11.管理员使用logAuditEvent记录审计事件，填写文本_action行为

12.管理员调用 resetElection() 重置系统。重置可能消耗大量gas.

