# shortcuts for calling common foundry commands

-include .env

# file to test 
FILE=

# specific test to run
TEST=

# block to test from 
BLOCK=17133822

# foundry test profile to run
PROFILE=$(TEST_PROFILE)

# forks from specific block 
FORK_BLOCK=--fork-block-number $(BLOCK)

# file to test
MATCH_PATH=--match-path src/test/$(FILE).t.sol

# test to run
MATCH_TEST=--match-test $(TEST)

# rpc url
FORK_URL=--fork-url https://eth-mainnet.alchemyapi.io/v2/$(ALCHEMY_API_KEY)

# generates and serves documentation locally on port 4000
docs_local :; forge doc --serve --port 4000

# generates and builds documentation to ./documentation
docs_build :; forge doc --build --out ./documentation

# generates gas reports for files in foundry.toml
gas_report :; FOUNDRY_PROFILE=$(PROFILE) forge snapshot $(FORK_URL) $(FORK_BLOCK) --gas-report

# runs all tests: "make test_all"
test_all :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL)

# runs all tests from a given block (setting block is optional): "make test_block BLOCK=17133822" (17133822 is a block where revenue handler deltas are passing)
test_block :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(FORK_BLOCK)

# runs test coverage: "make test_coverage" add "--report lcov" to use with lcov reporter
test_coverage :; FOUNDRY_PROFILE=$(PROFILE) forge coverage $(FORK_URL) --report lcov

# runs test coverage: "make test_summary" to get output in terminal
test_summary :; FOUNDRY_PROFILE=$(PROFILE) forge coverage $(FORK_URL) --report summary

# runs test coverage for specific file: "make test_summary_file FILE=Minter" to use with lcov reporter
test_coverage_file :; FOUNDRY_PROFILE=$(PROFILE) forge coverage $(FORK_URL) $(MATCH_PATH) --report lcov

# runs test coverage for specific file: "make test_summary_file FILE=Minter"
test_summary_file :; FOUNDRY_PROFILE=$(PROFILE) forge coverage $(FORK_URL) $(MATCH_PATH) --report summary

# runs all tests with added verbosity for failing tests: "make test_debug"
test_debug :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) -vvv

# runs specific test file with console logs: "make test_file FILE=Minter"
test_file :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) -vv

test_file_test :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) $(MATCH_TEST) -vv

# runs specific test file with added verbosity for failing tests: "make test_file_debug FILE=Minter"
test_file_debug :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) -vvv

# runs specific test file from a given block (setting block is optional): "make test_file_block FILE=Minter"
test_file_block :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) $(FORK_BLOCK)

# runs specific test file with added verbosity for failing tests from a given block: "make test_file_block_debug FILE=Minter"
test_file_block_debug :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) $(FORK_BLOCK) -vvv

# runs single test within file with added verbosity for failing test: "make test_file_debug_test FILE=Minter TEST=testUnwrap"
test_file_debug_test :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) $(MATCH_TEST) -vvv

# runs single test within file with added verbosity for failing test from a given block: "make test_file_block_debug_test FILE=Minter TEST=testUnwrap"
test_file_block_debug_test :; FOUNDRY_PROFILE=$(PROFILE) forge test $(FORK_URL) $(MATCH_PATH) $(MATCH_TEST) $(FORK_BLOCK) -vvv

# | File                       | % Lines            | % Statements       | % Branches       | % Funcs          |
# |----------------------------|--------------------|--------------------|------------------|------------------|
# | src/RewardsDistributor.sol | 90.00% (126/140)   | 87.44% (174/199)   | 69.70% (46/66)   | 80.00% (12/15)   |
# | src/Bribe.sol              | 92.47% (135/146)   | 93.44% (171/183)   | 78.38% (58/74)   | 78.95% (15/19)   |
# | src/VotingEscrow.sol       | 93.96% (467/497)   | 94.13% (577/613)   | 77.65% (205/264) | 90.00% (72/80)   |
# | src/Voter.sol              | 98.86% (173/175)   | 99.01% (200/202)   | 83.96% (89/106)  | 96.67% (29/30)   |
# | src/Minter.sol             | 100.00% (48/48)    | 100.00% (61/61)    | 88.46% (23/26)   | 100.00% (9/9)    |
# | src/FluxToken.sol          | 97.06% (66/68)     | 97.40% (75/77)     | 90.32% (56/62)   | 100.00% (19/19)  |
# | src/RevenueHandler.sol     | 100.00% (94/94)    | 100.00% (115/115)  | 93.18% (41/44)   | 100.00% (15/15)  |
# | src/RewardPoolManager.sol  | 100.00% (47/47)    | 100.00% (55/55)    | 94.12% (32/34)   | 100.00% (13/13)  |
# | src/AlchemixGovernor.sol   | 100.00% (16/16)    | 100.00% (17/17)    | 100.00% (12/12)  | 100.00% (6/6)    |
# | src/BaseGauge.sol          | 100.00% (13/13)    | 100.00% (13/13)    | 100.00% (14/14)  | 80.00% (4/5)     |
# | src/BribeFactory.sol       | 100.00% (1/1)      | 100.00% (2/2)      | 100.00% (0/0)    | 100.00% (1/1)    |
# | src/GaugeFactory.sol       | 100.00% (2/2)      | 100.00% (4/4)      | 100.00% (0/0)    | 100.00% (2/2)    |
# | src/PassthroughGauge.sol   | 100.00% (2/2)      | 100.00% (2/2)      | 100.00% (0/0)    | 100.00% (1/1)    |