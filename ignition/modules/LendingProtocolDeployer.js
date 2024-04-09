const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const lpTokenAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

module.exports = buildModule("LendingProtocol", (m) => {
  const lpToken = m.getParameter("lpToken", lpTokenAddress);

  const lendingProtocol = m.contract("LendingProtocol", [lpToken]);

  // If you need to call any functions after deployment, you can do that here
  // m.call(lendingProtocol, "someFunction", [...args]);

  return { lendingProtocol };
});
