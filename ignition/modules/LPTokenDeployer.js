const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("LPToken", (m) => {
  const lpToken = m.contract("LPToken");

  // If you need to call any functions after deployment, you can do that here
  // m.call(lpToken, "someFunction", [...args]);

  return { lpToken };
});
