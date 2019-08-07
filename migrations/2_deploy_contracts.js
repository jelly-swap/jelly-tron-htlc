var HashTimeLock = artifacts.require("./HashTimeLock.sol");

module.exports = function(deployer) {
   deployer.deploy(HashTimeLock);
};
