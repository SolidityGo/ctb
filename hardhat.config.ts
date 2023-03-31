import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

module.exports = {
    zksolc: {
        version: "1.3.7",
        compilerSource: "binary",
        settings: {},
    },
    defaultNetwork: "zkTestnet",
    networks: {
        zkTestnet: {
            url: "https://zksync2-testnet.zksync.dev", // URL of the zkSync network RPC
            ethNetwork: "goerli", // Can also be the RPC URL of the Ethereum network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
        },

        'zk-internal-ctf': {
            url: 'https://mainnet.era.zksync.io',
            accounts: {
                mnemonic: process.env.INTERNAL_CTF || "test test test test test test test test test test test test",
                count: 100,
            },
            zksync: true,
            ethNetwork: 'https://rpc.ankr.com/eth',

            // verifyURL: 'https://explorer.zksync.io/contracts/verify'
            verifyURL: 'https://zksync2-mainnet-explorer.zksync.io/contract_verification'

        },
    },

    solidity: {
        compilers: [
            {
                version: "0.4.18",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: "0.5.16",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: "0.6.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: "0.7.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: "0.8.15",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },
            {
                version: "0.8.16",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            },

        ]
    },

};
