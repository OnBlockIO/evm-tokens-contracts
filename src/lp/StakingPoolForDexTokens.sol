// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @notice Staking Pool for Dex Tokens Contract
contract StakingPoolForDexTokens is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserInfo {
        uint256 amount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
    }

    /// @notice precision factor for reward calculation
    uint256 public constant PRECISION_FACTOR = 10 ** 12;

    /// @notice address of reward token
    IERC20Upgradeable public ghostMarketToken;

    /// @notice address of staked token
    IERC20Upgradeable public stakedToken;

    /// @notice block number for rewards start
    uint256 public startBlock;

    /// @notice accumulated tokens per share
    uint256 public accTokenPerShare;

    /// @notice block number for rewards end
    uint256 public endBlock;

    /// @notice block number for last updated
    uint256 public lastRewardBlock;

    /// @notice tokens rewards per block
    uint256 public rewardPerBlock;

    /// @notice address to userInfo mapping
    mapping(address => UserInfo) public userInfo;

    /// @notice This event is emitted when an admin deposit rewards
    /// @param amount amount deposited
    event AdminRewardDeposit(uint256 amount);

    /// @notice This event is emitted when an admin withdraw rewards
    /// @param amount amount withdrawn
    event AdminRewardWithdraw(uint256 amount);

    /// @notice This event is emitted when a user deposit tokens
    /// @param user user that triggered it
    /// @param amount amount deposited
    /// @param harvestedAmount amount of rewards harvested
    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);

    /// @notice This event is emitted when a user withdraw in emergency
    /// @param user user that triggered it
    /// @param amount amount withdrawn
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /// @notice This event is emitted when a user harvest rewards
    /// @param user user that triggered it
    /// @param harvestedAmount amount of rewards harvested
    event Harvest(address indexed user, uint256 harvestedAmount);

    /// @notice This event is emitted when a new reward per block and end block is set
    /// @param rewardPerBlock new reward per block
    /// @param endBlock new end block
    event NewRewardPerBlockAndEndBlock(uint256 rewardPerBlock, uint256 endBlock);

    /// @notice This event is emitted when a user withdraw tokens
    /// @param user user that triggered it
    /// @param amount amount withdrawn
    /// @param harvestedAmount amount of rewards harvested
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);

    /// @notice Initialize the contract
    /// @param _stakedToken staked token address
    /// @param _ghostMarketToken reward token address
    /// @param _rewardPerBlock reward per block (in ghostMarketToken)
    /// @param _startBlock start block
    /// @param _endBlock end block
    function initialize(
        address _stakedToken,
        address _ghostMarketToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public virtual initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        stakedToken = IERC20Upgradeable(_stakedToken);
        ghostMarketToken = IERC20Upgradeable(_ghostMarketToken);
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    /// @notice Deposit staked tokens
    /// @param amount amount to deposit (in stakedToken)
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Deposit: Amount must be > 0");

        _updatePool();

        uint256 pendingRewards;

        if (userInfo[msg.sender].amount > 0) {
            pendingRewards =
                ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
                userInfo[msg.sender].rewardDebt;

            if (pendingRewards > 0) {
                ghostMarketToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        stakedToken.safeTransferFrom(msg.sender, address(this), amount);

        userInfo[msg.sender].amount += amount;
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;

        emit Deposit(msg.sender, amount, pendingRewards);
    }

    /// @notice Harvest tokens that are pending
    function harvest() external nonReentrant whenNotPaused {
        _updatePool();

        uint256 pendingRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        require(pendingRewards > 0, "Harvest: Pending rewards must be > 0");

        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;
        ghostMarketToken.safeTransfer(msg.sender, pendingRewards);

        emit Harvest(msg.sender, pendingRewards);
    }

    /// @notice Withdraw staked tokens and give up rewards
    /// @dev only for emergency. it does not update the pool.
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint256 userBalance = userInfo[msg.sender].amount;

        require(userBalance != 0, "Withdraw: Amount must be > 0");

        // Reset internal value for user
        userInfo[msg.sender].amount = 0;
        userInfo[msg.sender].rewardDebt = 0;

        stakedToken.safeTransfer(msg.sender, userBalance);

        emit EmergencyWithdraw(msg.sender, userBalance);
    }

    /// @notice Withdraw staked tokens and collect reward tokens
    /// @param amount amount to withdraw (in stakedToken)
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(
            (userInfo[msg.sender].amount >= amount) && (amount > 0),
            "Withdraw: Amount must be > 0 or lower than user balance"
        );

        _updatePool();

        uint256 pendingRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
            userInfo[msg.sender].rewardDebt;

        userInfo[msg.sender].amount -= amount;
        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;

        stakedToken.safeTransfer(msg.sender, amount);

        if (pendingRewards > 0) {
            ghostMarketToken.safeTransfer(msg.sender, pendingRewards);
        }

        emit Withdraw(msg.sender, amount, pendingRewards);
    }

    /// @notice Withdraw rewards (for admin)
    /// @param amount amount to withdraw (in ghostMarketToken)
    /// @dev only callable by owner
    function adminRewardWithdraw(uint256 amount) external onlyOwner whenNotPaused {
        ghostMarketToken.safeTransfer(msg.sender, amount);

        emit AdminRewardWithdraw(amount);
    }

    /// @notice Pause
    /// @dev it allows calling emergencyWithdraw
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpause
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Update reward per block and the end block
    /// @param newRewardPerBlock new reward per block
    /// @param newEndBlock new end block
    function updateRewardPerBlockAndEndBlock(
        uint256 newRewardPerBlock,
        uint256 newEndBlock
    ) external onlyOwner whenNotPaused {
        if (block.number >= startBlock) {
            _updatePool();
        }
        require(newEndBlock > block.number, "Owner: New endBlock must be after current block");
        require(newEndBlock > startBlock, "Owner: New endBlock must be after start block");

        endBlock = newEndBlock;
        rewardPerBlock = newRewardPerBlock;

        emit NewRewardPerBlockAndEndBlock(newRewardPerBlock, newEndBlock);
    }

    /// @notice Top up rewards pool
    /// @param amount amount to withdraw (in ghostMarketToken)
    function adminRewardDeposit(uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "UpdateRewards: Amount must be > 0");

        _updatePool();

        ghostMarketToken.safeTransferFrom(msg.sender, address(this), amount);

        emit AdminRewardDeposit(amount);
    }

    /// @notice View function to see pending reward on frontend
    /// @param user address of the user
    /// @return rewards pending rewards
    function calculatePendingRewards(address user) external view whenNotPaused returns (uint256) {
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if ((block.number > lastRewardBlock) && (stakedTokenSupply != 0)) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare = accTokenPerShare + (tokenReward * PRECISION_FACTOR) / stakedTokenSupply;

            return (userInfo[user].amount * adjustedTokenPerShare) / PRECISION_FACTOR - userInfo[user].rewardDebt;
        } else {
            return (userInfo[user].amount * accTokenPerShare) / PRECISION_FACTOR - userInfo[user].rewardDebt;
        }
    }

    /// @notice Update reward variables of the pool to be up-to-date
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * rewardPerBlock;

        // Update only if token reward for staking is not null
        if (tokenReward > 0) {
            accTokenPerShare = accTokenPerShare + ((tokenReward * PRECISION_FACTOR) / stakedTokenSupply);
        }

        // Update last reward block only if it wasn't updated after or at the end block
        if (lastRewardBlock <= endBlock) {
            lastRewardBlock = block.number;
        }
    }

    /// @notice Return reward multiplier over the given "from" to "to" block
    /// @param from block to start calculating reward
    /// @param to block to finish calculating reward
    /// @return multiplier for the period
    function _getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }
}
