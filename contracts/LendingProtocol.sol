// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import "./LPToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LendingProtocol is ReentrancyGuard {
    //variables

    //put lptoken contract into a variable
    LPToken public lpToken;
    uint256 public totalLiquidity; //lpToken.balanceOf(address(this));
    // uint256 public totalEthLocked; //unncessary in our case since we can query the contract balance directly
    uint256 public collateralRatio;
    // uint8 public liquidationThreshold = 80;
    uint8 public interestRate; //weekly interest rate (in percentage)
    //mock ETH price
    uint16 public ethPrice = 3000;

    //events
    event DepositedLPT(address indexed user, uint256 amountLPT);
    event DepositedETH(address indexed user, uint256 amountETH);
    event WithdrawnLPT(address indexed user, uint256 amountLPT);
    // event WithdrawnETH(address indexed user, uint256 amountETH);
    // event BorrowedETH(address indexed user, uint256 amountETH);
    // event BorrowedLPT(address indexed user, uint256 amountLPT);
    event RepaidETH(address indexed user, uint256 amountETH);
    // event RepaidLPT(address indexed user, uint256 amountLPT);

    //mappings

    //borrowers give ETH and borrow LPT
    //lenders lend LPT and earn interest

    mapping(address => BorrowerInfo) public borrowers;
    mapping(address => LenderInfo) public lenders;

    //structs
    struct BorrowerInfo {
        uint256 ehtDeposited;
        uint256 collateralValue; //USD value of deposited ETH at the time of deposit.
        uint256 depositTime;
    }

    struct LenderInfo {
        uint256 amountLent;
        uint256 interestEarned;
        uint256 depositTime;
    }

    constructor(address _lpToken) {
        lpToken = LPToken(_lpToken); // Set the LPToken address during deployment
        totalLiquidity = 0; // Assuming zero initial liquidity
        collateralRatio = 80;
        interestRate = 3;
    }

    //functions
    //view functions
    function getTotalLiquidity() public view returns (uint256) {
        // Recalculate totalLiquidity every time this function is called
        return lpToken.balanceOf(address(this));
    }

    function getTotalEthLocked() public view returns (uint256) {
        // Recalculate totalEthLocked every time this function is called
        uint256 ethBalance = address(this).balance;
        console.log("ETH balance of the contract:", ethBalance);
        return ethBalance;
    }

    function getBorrowerInfo(
        address _user
    ) public view returns (BorrowerInfo memory) {
        return borrowers[_user];
    }

    function getLenderInfo(
        address _user
    ) public view returns (LenderInfo memory) {
        return lenders[_user];
    }

    //helper functions

    function calculateLPTokensToUser(
        uint256 _ethAmount
    ) internal view returns (uint256) {
        // Normally we'd fetch ETH price from Chainlink oracle
        //But here we'll use a mock value

        // Calculate USD value of deposited ETH (ETH price being 3k)
        // console.log("ETH amount:", _ethAmount);
        uint256 depositValueUSD = _ethAmount * ethPrice;
        //only 80% of the deposited ETH can be used by the user
        console.log("Deposit value in USD:", depositValueUSD);
        //lptAmount returns 0 if I don't use safemath
        uint256 lptAmount = (depositValueUSD * collateralRatio) / 100;
        console.log("LPTokens to be minted:", lptAmount);
        console.log("collateral ratio:", collateralRatio);
        return lptAmount;
    }

    function transferLPTtoUser(
        address _user,
        uint256 _ethAmountDeposited
    ) internal {
        //1 LPT= 1 USD
        //1 ETH = 3000 USD
        uint256 lptAmount = (calculateLPTokensToUser(_ethAmountDeposited));
        console.log("LPToken amount to be minted:", lptAmount);

        // send the user LPTokens using ERC20's transfer function
        lpToken.transfer(_user, lptAmount);
    }

    //change this function as it only works for depositing but not withdrawing
    function updateBorrowerInfo(address _user, uint256 _amount) internal {
        borrowers[_user].ehtDeposited += _amount;
        borrowers[_user].collateralValue += (calculateLPTokensToUser(_amount));
        borrowers[_user].depositTime = block.timestamp;
    }

    function calculateDaysPassed(
        uint256 timestamp1,
        uint256 timestamp2
    ) internal pure returns (uint256) {
        require(
            timestamp1 <= timestamp2,
            "First timestamp must be earlier or equal to the second timestamp"
        );

        uint256 secondsPassed = timestamp2 - timestamp1;
        uint256 daysPassed = secondsPassed / 86400; // Number of seconds in a day

        console.log("Number of days passed:", daysPassed);
        return daysPassed;
    }

    function calculateInterest() public view returns (uint256) {
        //call calculateDaysPassed function
        uint256 daysPassed = calculateDaysPassed(
            lenders[msg.sender].depositTime,
            block.timestamp
        );

        //typecasting
        uint8 remainingDays = uint8(daysPassed % 30);

        //check if 30 days has passed
        //via a custom error

        require(daysPassed >= 30, "Withdraw cycle isn't completed yet.");

        //divide the dayspassed by 30 to get amount of months passed
        uint256 monthsPassed = daysPassed / 30;
        //calculate interest
        //the reason we divide by 100 at the end and not the interestRate is because
        //Solidity doesn't accept decimal numbers...
        uint256 interest = (lenders[msg.sender].amountLent *
            (interestRate) *
            monthsPassed) / 100;

        console.log("amount lent:", lenders[msg.sender].amountLent);
        console.log("Interest earned:", interest);
        console.log("Months passed:", monthsPassed);
        console.log("remaining days:", remainingDays);

        return interest;
    }

    //main functions start

    function depositETH(uint256 _amount) public payable nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        // console.log("deposited amount", _amount);

        //call function to transfer LPTokens to user
        transferLPTtoUser(msg.sender, _amount);

        //call function to update user's deposit information
        updateBorrowerInfo(msg.sender, _amount);
    }

    //lenders use this function
    function depositLPT(uint256 _lptAmount) public {
        //check if _lptAmount is greater than 0
        require(_lptAmount > 0, "Amount must be greater than 0");

        //transfers the LPTokens to the protocol
        lpToken.transferFrom(msg.sender, address(this), _lptAmount);

        //push the user to the lenders mapping
        lenders[msg.sender].amountLent += _lptAmount;
        lenders[msg.sender].depositTime = block.timestamp;

        // Emit an event after successful transfer
        emit DepositedLPT(msg.sender, _lptAmount);
        console.log(block.timestamp);
    }

    function withdrawInterest() public {
        //check if the user has ever lent any LPTokens
        require(
            lenders[msg.sender].depositTime != 0,
            "You are not a lender or have not lent any LPTokens"
        );

        //call calculateInterest function
        uint256 interest = calculateInterest();

        //transfers the LPTokens to the user from the protocol
        lpToken.transfer(msg.sender, interest);
        //update the user's interest to 0
        lenders[msg.sender].interestEarned = 0;
        lenders[msg.sender].depositTime = block.timestamp;

        //emit event
        emit WithdrawnLPT(msg.sender, interest);
    }

    function repayDebt() public {
        //check if the borrower has collateralValue more than 0
        require(
            borrowers[msg.sender].collateralValue > 0,
            "You do not have any debt."
        );
        //the user pays all of their debt
        lpToken.transferFrom(
            msg.sender,
            address(this),
            borrowers[msg.sender].collateralValue
        );
        //update the user's debt to 0
        borrowers[msg.sender].collateralValue = 0;

        //send locked ETH to the user
        payable(msg.sender).transfer(borrowers[msg.sender].ehtDeposited);

        //update locked ETH
        borrowers[msg.sender].ehtDeposited = 0;

        //emit event
        emit RepaidETH(msg.sender, borrowers[msg.sender].ehtDeposited);
    }

    //should also repay the interest to the user
    function withdrawLiquidity() public {
        //check if the user has ever lent any LPTokens
        require(
            lenders[msg.sender].depositTime != 0,
            "You are not a lender or have not lent any LPTokens"
        );
        //calculates the interest
        uint256 interest = calculateInterest();

        //add amountLent and interestEarned together
        uint256 totalAmount = lenders[msg.sender].amountLent + interest;

        //transfers the LPTokens to the user from the protocol
        lpToken.transfer(msg.sender, totalAmount);

        //update the user's information
        lenders[msg.sender].interestEarned = 0;
        lenders[msg.sender].amountLent = 0;
        lenders[msg.sender].depositTime = block.timestamp;

        //emit event
        emit WithdrawnLPT(msg.sender, totalAmount);
    }

    fallback() external payable {
        revert("Cannot send ETH directly to the contract");
    }

    receive() external payable {
        revert("Cannot send ETH directly to the contract");
    }
}
