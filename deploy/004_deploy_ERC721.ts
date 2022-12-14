import hre, {deployments, getNamedAccounts} from 'hardhat';

async function main() {
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  const CHAIN = hre.network.name;
  const IS_MAINNET = true;
  const NAME = 'GhostMarket ERC721';
  const SYMBOL = 'GHOST';
  const API_PATH = IS_MAINNET ? 'api' : 'api-testnet';
  const API_URL = `https://${API_PATH}.ghostmarket.io/metadata/${CHAIN}`;

  await deploy('GhostMarketERC721', {
    contract: 'GhostMarketERC721',
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [NAME, SYMBOL, API_URL],
        },
      },
    },
    log: true,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
