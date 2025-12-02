-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployCarbonMarketplace.s.sol:DeployCarbonMarketplace --rpc-url $(SEPOLIA_RPC_URL) --account account1 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv