const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const lpTokenAddress = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";

module.exports = buildModule("LendingProtocol", (m) => {
  const lpToken = m.getParameter("lpToken", lpTokenAddress);

  const lendingProtocol = m.contract("LendingProtocol", [lpToken]);

  // If you need to call any functions after deployment, you can do that here
  // m.call(lendingProtocol, "someFunction", [...args]);

  return { lendingProtocol };
});
