# L2GovernorVotes
[Git Source](https://github.com/alchemix-finance/alchemix-v2-dao/blob/ede6fa522daa0fff2c20e5420d5e76d74abb70c3/src/governance/L2GovernorVotes.sol)

**Inherits:**
[L2Governor](/src/governance/L2Governor.sol/abstract.L2Governor.md)

**Author:**
Modified from RollCall (https://github.com/withtally/rollcall/blob/main/src/standards/L2GovernorVotes.sol)

*Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
_Available since v4.3._*


## State Variables
### token

```solidity
IVotes public immutable token;
```


## Functions
### constructor


```solidity
constructor(IVotes tokenAddress);
```

### _getVotes

Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).


```solidity
function _getVotes(address account, uint256 blockTimestamp, bytes memory)
    internal
    view
    virtual
    override
    returns (uint256);
```

