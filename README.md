
# GhostMarket Tokens Contracts

[![codecov](https://codecov.io/github/OnBlockIO/evm-tokens-contracts/branch/master/graph/badge.svg?token=SHNSP3GCXL)](https://codecov.io/github/OnBlockIO/evm-tokens-contracts)

## Deployed Contracts on BSC:

#### OnBlockVesting
https://bscscan.com/address/0xFC2eb99ABAe550903a41DafCb6D797BcD0D88758

#### GhostMarketERC721
https://bscscan.com/address/0xf41db445d7eaf45536985ce185ce131fa4b42e68

#### GhostMarketERC1155
https://bscscan.com/address/0x44c5ce28c29934b71a2a0447745d551dfc7b5133

#### GhostMarketToken
https://bscscan.com/address/0x42bD1B1c84aD8Cf576D25FCd86A7EFbE2752Fe02

#### ProxyAdmin
https://bscscan.com/address/0xC200F605Ee4b8a151532e8691f33AF8cC26EB99f
https://bscscan.com/address/0xdcdab251151c345ad527851eca783521ea3209e0

#### TransparentUpgradeableProxy
https://bscscan.com/address/0x0B53b5dA7d0F275C31a6A182622bDF02474aF253
https://bscscan.com/address/0x26d583e2cda958b13cc319fad124aa729f8a196e
https://bscscan.com/address/0xe98e9d752d6104ada0520988cd1834035762c8c7

## Deployed Contracts on Polygon:

#### GhostMarketERC721
https://polygonscan.com/address/0x068bef92987d16ef682ff017b822ca1211401eaf

#### GhostMarketERC1155
https://polygonscan.com/address/0xf1c82f5ddb4f1a6a8f3eed2eb25fc39fc6d33fb3

#### GhostMarketToken
https://polygonscan.com/address/0x68F50816df86F7a2f720deFfFF2395a9F1675585

#### ProxyAdmin
https://polygonscan.com/address/0x1bb6C21e6adB8757F46e77A7F4c5Ad9118f4A04d
https://polygonscan.com/address/0xf41db445d7eaf45536985ce185ce131fa4b42e68

#### TransparentUpgradeableProxy
https://polygonscan.com/address/0x6a335AC6A3cdf444967Fe03E7b6B273c86043990
https://polygonscan.com/address/0xdcdab251151c345ad527851eca783521ea3209e0

## Deployed Contracts on Avalanche:

#### GhostMarketERC721
https://snowtrace.io/address/0x068bef92987d16ef682ff017b822ca1211401eaf

#### GhostMarketERC1155
https://snowtrace.io/address/0xdcdab251151c345ad527851eca783521ea3209e0

#### GhostMarketToken
https://snowtrace.io/address/0x42bD1B1c84aD8Cf576D25FCd86A7EFbE2752Fe02

#### ProxyAdmin
https://snowtraceio/address/0xC200F605Ee4b8a151532e8691f33AF8cC26EB99f
https://snowtrace.io/address/0xf1c82f5ddb4f1a6a8f3eed2eb25fc39fc6d33fb3

#### TransparentUpgradeableProxy
https://snowtrace.io/address/0x0B53b5dA7d0F275C31a6A182622bDF02474aF253
https://snowtrace.io/address/0xf41db445d7eaf45536985ce185ce131fa4b42e68
https://snowtrace.io/address/0x26d583e2cda958b13cc319fad124aa729f8a196e

## Deployed Contracts on Ethereum:

#### GhostMarketToken
https://etherscan.com/address/0x42bD1B1c84aD8Cf576D25FCd86A7EFbE2752Fe02

#### ProxyAdmin
https://etherscan.com/address/0xA93Ae78470b46c75523aCBACfc68246Bf2Eb68ce

#### TransparentUpgradeableProxy
https://etherscan.com/address/0x35609dC59E15d03c5c865507e1348FA5abB319A8

## Audit
https://www.certik.com/projects/ghostmarket

## Technical Information
Using OpenZeppelin contracts.
- Upgradable ERC20/ERC721/ERC1155 smart contracts.
- Upgradable lazy minting proxies smart contracts.
- Upgradable LP staking smart contract.
- Non-upgradable vesting smart contract.

### Compiling contracts
```
hardhat compile
```

### Deploying Proxy
Using hardhat to deploy proxy contracts

#### locally
```
hardhat run deploy/001_deploy_ERC20.ts
hardhat run deploy/002_deploy_Vesting.ts
hardhat run deploy/003_deploy_LPStaking.ts
hardhat run deploy/004_deploy_ERC721.ts
hardhat run deploy/005_deploy_ERC1155.ts
```

#### to network
```
hardhat run --network <network_name> deploy/<deploy_script>.ts
```
For deployment private keys must be saved into

```
.secrets.json
```

secrets.json structure:

```
{
    "ETH_NODE_URI": "key",
    "TESTNET_PRIVATE_KEY": ["key1","key2","key3","key4"],
    "MAINNET_PRIVATE_KEY": ["key1","key2","key3","key4"],
    "ETHERSCAN_API_KEY": "key"
}
```

## Testing
tests can be run with:

```
hardhat test
```

```
hardhat test <network_name>
```

## Coverage
coverage can be run with:

```
hardhat coverage
```

```
hardhat coverage <network_name>
```

## Verifying contracts
```
hardhat verify --network <network_name> <0x_contract_address>
```


