# AlchemixGovernorTest
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/test/AlchemixGovernor.t.sol)

**Inherits:**
[BaseTest](/src/test/BaseTest.sol/contract.BaseTest.md)


## State Variables
### tokenId1

```solidity
uint256 tokenId1;
```


### tokenId2

```solidity
uint256 tokenId2;
```


### tokenId3

```solidity
uint256 tokenId3;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### craftTestProposal


```solidity
function craftTestProposal()
    internal
    view
    returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description);
```

### testExecutorCanCreateGaugesForAnyAddress


```solidity
function testExecutorCanCreateGaugesForAnyAddress(address a) public;
```

### testVeAlcxMergesAutoDelegates


```solidity
function testVeAlcxMergesAutoDelegates() public;
```

### testProposeFail


```solidity
function testProposeFail() public;
```

### testPropose


```solidity
function testPropose() public;
```

### testProposalExecutionTimestamp


```solidity
function testProposalExecutionTimestamp() public;
```

### testProposalNeedsQuorumToPass


```solidity
function testProposalNeedsQuorumToPass() public;
```

### testProposalHasQuorum


```solidity
function testProposalHasQuorum() public;
```

### testOnlyExecutorCanExecute


```solidity
function testOnlyExecutorCanExecute() public;
```

### testUpdateProposalNumerator


```solidity
function testUpdateProposalNumerator() public;
```

### testProposalThresholdMetBeforeProposalBlock


```solidity
function testProposalThresholdMetBeforeProposalBlock() public;
```

### testSetVotingDelay


```solidity
function testSetVotingDelay() public;
```

### testSetVotingPeriod


```solidity
function testSetVotingPeriod() public;
```

### testTimelockSchedulerRoleSchedule


```solidity
function testTimelockSchedulerRoleSchedule() public;
```

### testFailTimelockSchedulerRoleScheduleBatch


```solidity
function testFailTimelockSchedulerRoleScheduleBatch() public;
```

### testCancellerRole


```solidity
function testCancellerRole() public;
```

