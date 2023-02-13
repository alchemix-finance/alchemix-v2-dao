# Alchemix DAO

## Getting Started

### Create a `.env` file with the following environment variables

```
ALCHEMY_API_KEY=<alchemy api key>
TEST_PROFILE=default
```

### Install latest version of foundry

`curl -L https://foundry.paradigm.xyz | bash`

### Install dependencies

`forge install`

## Testing

### Run all foundry tests at specific block

`make test_block`

### Run all foundry tests at current block

`make test_all`

### Coverage report in terminal

`make test_summary`

### Coverage report lcov file

`make test_coverage`

## Documentation

### on localhost

Generate natspec documentation locally with `make docs_local`

### to ouput file

Generate and build documentation to ./documentation with `make docs_build`

## Inside Audit Scope

### src

AlchemixGovernor.sol, BaseGauge.sol, Bribe.sol, CurveEthPoolAdapter.sol, CurveMetaPoolAdapter.sol, FluxToken.sol, Minter.sol, RevenueHandler.sol, Voter.sol, VotingEscrow.sol

### src/gauges

CurveGauge.sol, PassthroughGauge.sol, StakingGauge.sol, StakingRewards.sol

### src/factories

BribeFactory.sol, GaugeFactory.sol

### src/governance

These are Open Zeppelin governance contracts with very minor changes
