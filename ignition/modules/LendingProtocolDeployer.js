const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const lpTokenAddress = "0x8615D77790F8A14E2dC996ba1eD7F040cE6A1d2B";

module.exports = buildModule("LendingProtocol", (m) => {
  const lpToken = m.getParameter("lpToken", lpTokenAddress);

  const lendingProtocol = m.contract("LendingProtocol", [lpToken]);

  // If you need to call any functions after deployment, you can do that here
  // m.call(lendingProtocol, "someFunction", [...args]);

  return { lendingProtocol };
});
