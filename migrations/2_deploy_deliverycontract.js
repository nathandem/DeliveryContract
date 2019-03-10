const DeliveryContract = artifacts.require("DeliveryContract");

module.exports = function(deployer) {
  deployer.deploy(DeliveryContract);
};
