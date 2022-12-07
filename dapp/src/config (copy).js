var txDefaultOrig =
{
  websites: {
    "wallet": "https://wallet.gnosis.pm",
    "gnosis": "https://gnosis.pm",
  "ethGasStation": "https://safe-relay.gnosis.pm/api/v1/gas-station/"
  },
  resources : {
    "termsOfUse": "https://wallet.gnosis.pm/TermsofUseMultisig.pdf",
    "privacyPolicy": "https://gnosis.io/privacy-policy",
    "imprint": "https://wallet.gnosis.pm/imprint.html"
  },
  gasLimit: 10000000,
  gasPrice:  80000000000,
  ethereumNode: "https://mainnet.infura.io:443",
  connectionChecker: {
    method : "OPTIONS",
    url : "https://www.google.com",
    checkInterval: 5000
  },
  accountsChecker: {
    checkInterval: 5000
  },
  transactionChecker: {
    checkInterval: 15000
  },
  wallet: "injected",
  defaultChainID: null,
  //Polygon Mainnet
  //modified factory address 6.12.2022
  walletFactoryAddress: "0x081ed6cc297e686414c11d758a23152d32e9ddf1",
  tokens: [
    {
      'address': '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
      'name': 'Tether USD',
      'symbol': 'USDT',
      'decimals': 18
    },
    {
      'address': '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      'name': 'USD Coin',
      'symbol': 'USDC',
      'decimals': 18
    },
    {
      'address': '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063',
      'name': 'DAI Stablecoin',
      'symbol': 'DAI',
      'decimals': 18
    },
    {
      'address': '0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6',
      'name': 'Wrapped Bitcoin',
      'symbol': '',
      'decimals': 18
    },
  ]
};

if (isElectron) {
  txDefaultOrig.wallet = "remotenode";
}

var txDefault = {
  ethereumNodes : [
    {
      url : "https://mainnet.infura.io:443",
      name: "Remote Mainnet"
    },
    {
      url : "https://ropsten.infura.io:443",
      name: "Remote Ropsten"
    },
    {
      url : "https://kovan.infura.io:443",
      name: "Remote Kovan"
    },
    {
      url : "https://rinkeby.infura.io:443",
      name: "Remote Rinkeby"
    },
    {
      url : "http://goerli.infura.io:443",
      name: "Remote Goerli"
    }
  ],
  walletFactoryAddresses: {
    'polygon': {
      name: 'Polygon',
      address: '0x081ed6cc297e686414c11d758a23152d32e9ddf1'
    },
    'ropsten': {
      name: 'Ropsten',
      address: '0x081ed6cc297e686414c11d758a23152d32e9ddf1'
    },
    'kovan': {
      name: 'Kovan',
      address: '0x081ed6cc297e686414c11d758a23152d32e9ddf1'
    },
    'rinkeby': {
      name: 'Rinkeby',
      address: '0x081ed6cc297e686414c11d758a23152d32e9ddf1'
    },
    'goerli': {
      name: 'Goerli',
      address: '0x081ed6cc297e686414c11d758a23152d32e9ddf1'
    }
  }
};

var oldWalletFactoryAddresses = [
  ("0x081ed6cc297e686414c11d758a23152d32e9ddf1").toLowerCase(),
  ("0x081ed6cc297e686414c11d758a23152d32e9ddf1").toLowerCase(),
  ("0x081ed6cc297e686414c11d758a23152d32e9ddf1").toLowerCase()
];

/**
* Update the default wallet factory address in local storage
*/
function checkWalletFactoryAddress() {
  var userConfig = JSON.parse(localStorage.getItem("userConfig"));

  if (userConfig && oldWalletFactoryAddresses.indexOf(userConfig.walletFactoryAddress.toLowerCase()) >= 0) {
    userConfig.walletFactoryAddress = txDefaultOrig.walletFactoryAddress;
    localStorage.setItem("userConfig", JSON.stringify(userConfig));
  }
}

/**
* Reload configuration
*/
function loadConfiguration () {
  var userConfig = JSON.parse(localStorage.getItem("userConfig"));
  Object.assign(txDefault, txDefaultOrig, userConfig);
}

checkWalletFactoryAddress();
loadConfiguration();
