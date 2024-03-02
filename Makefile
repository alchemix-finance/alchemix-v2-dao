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

# shortcuts for deploying contracts

# Mainnet rpc url
RPC=https://eth-mainnet.alchemyapi.io/v2/$(ALCHEMY_API_MAINNET_KEY)

# Sepolia rpc url 
TESTNET_RPC=https://eth-sepolia.g.alchemy.com/v2/$(ALCHEMY_API_KEY_SEPOLIA)

# add constructor args as needed (weth, balancer vault, sushi router)
ARGS=--constructor-args 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

# etherscan verification
VERIFY=--etherscan-api-key $(ETHERSCAN_API_KEY) --verify

# private key for deployment
KEY=--private-key $(PRIVATE_KEY)

# Mainnet deployment command
DEPLOY_MAINNET=--rpc-url $(RPC) $(ARGS) $(KEY) $(VERIFY) src/$(FILE).sol:$(FILE)

# Sepolia deployment command
DEPLOY_SEPOLIA=--rpc-url $(TESTNET_RPC) $(ARGS) $(KEY) $(VERIFY) src/$(FILE).sol:$(FILE)

# Deploy a contract to mainnet (assumes file and contract name match) "make deploy_mainnet FILE=<filename>"
deploy_mainnet :; forge create $(DEPLOY_MAINNET)

# Deploy a contract to sepolia (assumes file and contract name match) "make deploy_sepolia FILE=<filename>"
deploy_sepolia :; forge create $(DEPLOY_SEPOLIA)

forge_script :; forge script script/VeAlcxTest.s.sol:VeAlcxScript --rpc-url $(TESTNET_RPC) $(KEY) --broadcast --verify -vvvv 



VotingEscrow 		0x6aA3223F4D250065C5194ee243d1D2C29D594033
AlcxBpt 			0x4dEDC07770A50F1a702C5C8b2AFD38Da46bE6072
Alcx 				0xdd9457fC996596b10aA01e4FFB4F65Ada2A63C3e
FluxToken 			0x2eEFEdce52f4C4dC5f89bFc8c4A6602E0fE6c19F
RewardPoolManager 	0xaAF0fc4fE1CDA6da8A1B076E532498940f6f0A11
RevenueHandler 		0xEf2539ad4BF8752809006E2e22A32ED80348a40d
GaugeFactory 		0x6ceCDfbA15ef61Cb67198E710AFDa69ECE074191
BribeFactory 		0x03a53bcA6E1CDcBA666960Fd98bac1536Ac5f696
Voter 				0x269d2c7275140fd466008Ec2aA4d1FDfF0c2EAe3
RewardsDistributor 	0xc304CbC791aa2dF8D6d1F6e79cC3fd68d1E3b48f
Minter 				0xc5eF0072f821afa016e33fD8D8476BF202735749
Bribe 				0x24fEaDDaf29162528455c7bf3D8bE1449e6152ba
PassthroughGauge 	0x157EE60B60D7ccfDF814A4366909099370D919f5