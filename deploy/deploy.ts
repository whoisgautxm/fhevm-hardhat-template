import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const deployed = await deploy("EmployerClaim", {
    from: deployer,
    args: ["0x194CDd095358eBAA5FD02913e5220E2cd7600713","0x48e6D166C0E10FF56e0F64caF579e6f92a201e7B"],
    log: true,
  });

  console.log(`EmployerClaim contract: `, deployed.address);
};
export default func;
func.id = "deploy_confidentialERC20"; // id required to prevent reexecution
func.tags = ["MyConfidentialERC20"];
