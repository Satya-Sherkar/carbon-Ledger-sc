-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployCarbonMarketplace.s.sol:DeployCarbonMarketplace --rpc-url $(SEPOLIA_RPC_URL) --account account1 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	forge script script/DeployCarbonMarketplace.s.sol:DeployCarbonMarketplace --rpc-url $(ANVIL_RPC_URL) --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  --broadcast -vvvv