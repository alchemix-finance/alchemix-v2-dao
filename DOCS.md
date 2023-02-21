# Alchemix DAO

## veALCX (VotingEscrow.sol)
The VotingEscrow contract is a ERC721 compliant NFT that allows users to lock their ALCX (in the form of an 80/20 BPT token) in order to gain voting power in the DAO.
- users can only stake a single LP token (80/20 BPT, yet to be deployed)
- users can lock their stake for a minimum of 1 epoch and a maximum of 26 epochs
- if a user deposits and sets `maxLockEnabled` to `true`, their lock time will be 26 epochs and will not decrease until they set `maxLockEnabled` to `false`
- users will receive the same amount of BPT tokens when they withdraw at the end of their stake
- users cannot withdraw their staked BPT until their lock time becomes 0, they call `startCooldown`, and wait 1 epoch
- the total amount of veALCX power in the system is equal to the sum of the powers of all individual veALCX NFTs
- when BPT is staked it is passed to a rewards pool (governance defined)
- when BPT is unstaked, it is withdrawn from the rewards pool
- governance can claim rewards generated from BPT staked in the rewards pool, sending them to the treasury

## Minter.sol
The Minter.sol contract controls the minting and distribution of new ALCX.
- anyone can call `updatePeriod` once at the beginning of an epoch
- the Minter will mint *Z* ALCX in the current epoch, and *Z'* ALCX in the next epoch, where *Z' = Z - 130*
- the Minter will mint the same amount of ALCX every epoch following the epoch where Z' = 2392609e18
- the Minter will distribute 50% of the minted ALCX to the RewardsDistributor
- the Minter will distribute 30% of the minted ALCX to the Voter
- the Minter will distribute 20% of the minted ALCX to the TimeGauge

## Voter.sol
The Voter.sol contract allows veALCX holders to vote on which gauges should receive its alotted ALCX emissions.
- each veALCX tokenId may vote 1 time every epoch
- each veALCX tokenId may distribute their voting power across any number of gauges
- the power of a veALCX tokenId is calculated at the timestamp of the block that they vote
- the amount of veALCX power voted on a single gauge in a given epoch is the sum of all veALCX power voted on that gauge over the course of that epoch
- the amount of ALCX distributed to a given gauge in a given epoch is directly proportional to the amount of voting power cast on that gauge out of all voting power cast to all gauges in that epoch

## BaseGauge.sol
The Gauge contracts inherit from BaseGauge and distribute the ALCX allocated during an epoch to each gauge.  Most gauges will be "pass-thru", meaning the LP tokens staked in the gauge are actually staked in a third-party contract, and the Alchemix gauge passes along the ALCX emitted either as a direct reward or as a bribe.

## Bribe.sol
The Bribe.sol contract distributes bribes for a given Gauge.  Each Gauge had a Bribe contract attached to it, and each Bribe can accept multiple (up to 16) different tokens as bribes.  During each epoch, veALCX stakers can collect bribes for a given gauge if they voted on that gauge in the previous epoch.
- the total amount of bribe `b` on pool `p` claimable by a veALCX NFT with token-ID `i` during a given epoch `n` is equal to the proportion of total veALCX power that that NFT used to vote on pool `p`

## FluxToken.sol
The FLUX token is a special reward token that accrues to veALCX positions each epoch, with the amount accrued being directly proportional to the amount of veALCX power held in that tokenID.
- FLUX can be burned (before being minted) to boost the voting power of a veALCX tokenID for the epoch that it is burned
- FLUX can be minted (instead of being burned) as an ERC20 token
- The minter role will be the VotingEscrow contract
- ERC20 FLUX cannot be burned to boost veALCX power
- ERC20 FLUX can be burned to unlock a veALCX position early

## RewardsDistributor.sol
The RewardsDistributor contract distributes ALCX rewards to veALCX positions.  Once per epoch, veALCX holders can claim their alotted ALCX from the RewardsDistributor, either by compounding it into the veALCX position, or directly taking the ALCX.
- if the user chooses to compound their ALCX rewards into their veALCX position, they must provide the necessary ETH to create the BPT tokens accepted by veALCX
- if the user chooses to take their ALCX rewards directly, they will receive their alotted ALCX minus a governance defined penalty
- the total amount of ALCX claimable by a veALCX NFT with token-ID `i` during a given epoch `n` is equal to the proportion of total veALCX power that that NFT held at the start of that epoch multiplied by the total amount of ALCX minted for that epoch and the governance-defined multiplier for directing ALCX emissions to veALCX holders

## RevenueHandler.sol
The RevenuHandler contract distributes protocol revenue to veALCX positions.  When `updatePeriod` is called to start each epoch, the `checkpoint` function is called that triggers the RevenueHandler to realize its revenue for the Alchemix Treasury and veALCX holders.
- 50% (governance defined) of the revenue is sent directly to the treasury in the form of the tokens in which the revenue was generated
- revenue tokens not sent to the treasury are sold for their corresponding alAssets that generated them, and realized as revenue for veALCX holders
- the total amount of revenue claimable by a veALCX NFT with token-ID `i` for a given epoch `n` is equal to the proportion of total veALCX power that that NFT held at the start of the previous epoch multiplied by the amount of revenue accrued by the protocol during the previous epoch

## AlchemixGovernor.sol
The AlchemixGovernor contract extends the Open Zeppelin governance system with Alchemix specific governance parameters. Minor changes have been introduced and specified below.
- chainId has been added to the proposal id computation
- timelock executor has been added to the governance system
- votingDelay and votingPeriod has been added to the governance system