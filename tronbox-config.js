const port = process.env.HOST_PORT || 9090;

module.exports = {
  networks: {
    mainnet: {
      privateKey: 'PLACE YOUR MAINNET PRIVATE KEY HERE',
      userFeePercentage: 100,
      feeLimit: 1e8,
      fullHost: 'https://api.trongrid.io',
      network_id: '1'
    },
    shasta: {
      privateKey: 'PLACE YOUR SHASTA PRIVATE KEY HERE',
      userFeePercentage: 50,
      feeLimit: 1e8,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '2'
    },
    development: {
      // For trontools/quickstart docker image
      privateKey: 'PLACE YOU DEV PRIVATE KEY HERE',
      userFeePercentage: 50,
      feeLimit: 1e8,
      fullHost: 'http://127.0.0.1:' + port,
      network_id: '9'
    }
  }
};
