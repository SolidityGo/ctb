.PHONY: build test install-dependencies

include .env

build:
	npx hardhat compile
	forge build

install-dependencies:
	npm install yarn -g
	yarn install
	forge install --no-git --no-commit foundry-rs/forge-std@v1.1.1
	forge install --no-git --no-commit openZeppelin/openzeppelin-contracts@v4.4.2
	forge install --no-git --no-commit openZeppelin/openzeppelin-contracts-upgradeable@v4.4.2
