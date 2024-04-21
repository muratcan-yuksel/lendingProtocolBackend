const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const lpTokenAddress = "0xe1cA49B9B6D13193eA943E58b25Ad214792b1B8C";

module.exports = buildModule("LendingProtocol", (m) => {
  const lpToken = m.getParameter("lpToken", lpTokenAddress);

  const lendingProtocol = m.contract("LendingProtocol", [lpToken]);

  // If you need to call any functions after deployment, you can do that here
  // m.call(lendingProtocol, "someFunction", [...args]);

  return { lendingProtocol };
});
