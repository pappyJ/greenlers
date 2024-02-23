// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// todo correct usdt precision issues
// todo continue looping when data is not found for batch withdraw

contract GreenlersStaking is Ownable {
  uint256 public stakeId;
  uint256 public BASE_MULTIPLIER;

  struct StakePool {
    address stakeToken;
    address rewardToken;
    uint256 rewardAmount;
    uint256 rewardBalance;
    uint256 startTime;
    uint256 endTime;
    uint256 tokensStaked;
    uint256 stakeBaseDecimals;
    uint256 rewardBaseDecimals;
    uint256 vestingStartTime;
    uint256 vestingCliff;
  }

  struct Staker {
    uint256 stakedAmount;
    uint256 claimedAmount;
    uint256 claimStart;
  }

  IERC20 public USDTInterface;

  mapping(uint256 => bool) public paused;
  mapping(uint256 => StakePool) public stakePool;
  mapping(address => mapping(uint256 => Staker)) public stakers;

  event StakePoolCreated(
    address stakeToken,
    address rewardToken,
    uint256 indexed _id,
    uint256 startTime,
    uint256 endTime,
    uint256 vestingStartTime,
    uint256 vestingCliff
  );

  //EVENTS

  event StakePoolUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);

  event TokensStaked(address indexed user, uint256 indexed id, uint256 tokensStaked, uint256 timestamp);

  event TokensWithdrawn(address indexed user, uint256 indexed id, uint256 stakedAmount, uint256 indexed withdrawAmount, uint256 timestamp);

  event TokensClaimed(address indexed user, uint256 indexed id, uint256 amount, uint256 timestamp);

  event PoolStakeTokenAddressUpdated(address indexed prevValue, address indexed newValue, uint256 timestamp);

  event PoolRewardTokenAddressUpdated(address indexed prevValue, address indexed newValue, uint256 timestamp);

  event PoolRewardAmountUpdated(uint256 indexed amount, uint256 indexed newValue);

  event StakePoolPaused(uint256 indexed id, uint256 timestamp);
  event StakePoolUnPaused(uint256 indexed id, uint256 timestamp);

  /**
   * @dev Initializes the contract and sets key parameters
   * @param _usdt USDT token contract address
   */
  constructor(address _usdt) {
    require(_usdt != address(0), "Zero USDT address");

    USDTInterface = IERC20(_usdt);
    BASE_MULTIPLIER = (10**18);
  }

  /**
   * @dev Creates a new staking pool
   * @param _stakeToken the token to be staked in the pool for rewards
   * @param _rewardToken the token to receive after staking period ends
   * @param _startTime start time of the staking
   * @param _endTime end time of the staking
   * @param _stakeBaseDecimals No of decimals for the token to be staked. (10**18), for 18 decimal token
   * @param _rewardBaseDecimals No of decimals for the token for rewards.
   * @param _vestingStartTime Start time for the vesting - UNIX timestamp
   * @param _vestingCliff Cliff period for vesting in seconds
   */
  function createPool(
    address _stakeToken,
    address _rewardToken,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _stakeBaseDecimals,
    uint256 _rewardBaseDecimals,
    uint256 _vestingStartTime,
    uint256 _vestingCliff
  ) external onlyOwner {
    require(_stakeToken != address(0), "Zero token address");
    require(_rewardToken != address(0), "Zero token address");
    require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");
    require(_stakeBaseDecimals > 0, "Zero decimals for the token");
    require(_rewardBaseDecimals > 0, "Zero decimals for the token");
    require(_vestingStartTime >= _endTime, "Vesting starts before Staking ends");

    stakeId++;

    stakePool[stakeId] = StakePool(
      _stakeToken,
      _rewardToken,
      0,
      0,
      _startTime,
      _endTime,
      0,
      _stakeBaseDecimals,
      _rewardBaseDecimals,
      _vestingStartTime,
      _vestingCliff
    );

    emit StakePoolCreated(_stakeToken, _rewardToken, stakeId, _startTime, _endTime, _vestingStartTime, _vestingCliff);
  }

  /**
   * @dev To Update the amount of the reward of a stake pool
   * @param _id The Id of the stake pool
   * @param _newValue The amount of the reward to claim in the stake pool
   */
  function updatePoolReward(uint256 _id, uint256 _newValue) public checkPoolId(_id) onlyOwner {
    require(_newValue > 0, "amount must be greater than 0");

    uint256 rewardTokenValue = _newValue * (10 ** stakePool[_id].rewardBaseDecimals);

    require(rewardTokenValue <= IERC20(stakePool[_id].rewardToken).balanceOf(address(this)), "Reward token value is greater than contract balance");

    uint256 _prevValue = stakePool[_id].rewardAmount;

    stakePool[_id].rewardAmount = _newValue;

    stakePool[_id].rewardBalance = _newValue;

    emit PoolRewardAmountUpdated(_prevValue, _newValue);
  }

  /**
   * @dev To update the usdt token address
   * @param _newAddress Sale token address
   */
  function changeUsdtAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    USDTInterface = IERC20(_newAddress);
  }

  /**
   * @dev To update the stake times before staking starts
   * @param _id StakePool id to update
   * @param _startTime New start time
   * @param _endTime New end time
   */
  function changeSaleTimes(
    uint256 _id,
    uint256 _startTime,
    uint256 _endTime
  ) external checkPoolId(_id) onlyOwner {
    require(_startTime > 0 || _endTime > 0, "Invalid parameters");
    if (_startTime > 0) {
      require(block.timestamp < stakePool[_id].startTime, "Sale already started");
      require(block.timestamp < _startTime, "Sale time in past");
      uint256 prevValue = stakePool[_id].startTime;
      stakePool[_id].startTime = _startTime;
      emit StakePoolUpdated(bytes32("START"), prevValue, _startTime, block.timestamp);
    }

    if (_endTime > 0) {
      require(block.timestamp < _endTime, "End time in the past");
      require(_endTime > stakePool[_id].startTime, "Invalid endTime");
      uint256 prevValue = stakePool[_id].endTime;
      stakePool[_id].endTime = _endTime;
      emit StakePoolUpdated(bytes32("END"), prevValue, _endTime, block.timestamp);
    }
  }

  /**
   * @dev To update the end time of staking after it starts
   * @param _id StakePool id to update
   * @param _newEndTime New end time
   */
  function changePoolEndtime(uint256 _id, uint256 _newEndTime) external checkPoolId(_id) onlyOwner {
    if (_newEndTime > 0) {
      require(block.timestamp < _newEndTime, "End time in the past");
      require(_newEndTime > stakePool[_id].startTime, "Invalid endTime");
      uint256 prevValue = stakePool[_id].endTime;
      stakePool[_id].endTime = _newEndTime;
      emit StakePoolUpdated(bytes32("END"), prevValue, _newEndTime, block.timestamp);
    }
  }

  /**
   * @dev To update the vesting start time
   * @param _id stakePool id to update
   * @param _vestingStartTime New vesting start time
   */
  function changeVestingStartTime(uint256 _id, uint256 _vestingStartTime) external checkPoolId(_id) onlyOwner {
    require(_vestingStartTime >= stakePool[_id].endTime, "Vesting starts before Staking ends");
    uint256 prevValue = stakePool[_id].vestingStartTime;
    stakePool[_id].vestingStartTime = _vestingStartTime;
    emit StakePoolUpdated(bytes32("VESTING_START_TIME"), prevValue, _vestingStartTime, block.timestamp);
  }

  /**
   * @dev To update the stake token address
   * @param _id StakePool id to update
   * @param _newAddress Sale token address
   */
  function changeStakeTokenAddress(uint256 _id, address _newAddress) external checkPoolId(_id) onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    address prevValue = stakePool[_id].stakeToken;
    stakePool[_id].stakeToken = _newAddress;
    emit PoolStakeTokenAddressUpdated(prevValue, _newAddress, block.timestamp);
  }

  /**
   * @dev To update the reward address
   * @param _id StakePool id to update
   * @param _newAddress reward address
   */
  function changeRewardTokenAddress(uint256 _id, address _newAddress) external checkPoolId(_id) onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    address prevValue = stakePool[_id].rewardToken;
    stakePool[_id].rewardToken = _newAddress;
    emit PoolRewardTokenAddressUpdated(prevValue, _newAddress, block.timestamp);
  }

  /**
   * @dev To pause the stake pool
   * @param _id stakePool id to update
   */
  function pauseStakePool(uint256 _id) external checkPoolId(_id) onlyOwner {
    require(!paused[_id], "Already paused");
    paused[_id] = true;
    emit StakePoolPaused(_id, block.timestamp);
  }

  /**
   * @dev To unpause the stake pool
   * @param _id stakePool id to update
   */
  function unPauseStakePool(uint256 _id) external checkPoolId(_id) onlyOwner {
    require(paused[_id], "Not paused");
    paused[_id] = false;
    emit StakePoolUnPaused(_id, block.timestamp);
  }

  /**
   * @dev To check valid stake pool id
   * @param _id stakePool id to update
   */
  modifier checkPoolId(uint256 _id) {
    require(_id > 0 && _id <= stakeId, "Invalid stake pool id");
    _;
  }

  /**
   * @dev To validate staking time is active and amount is greater than zero
   * @param _id stakePool id to check
   * @param amount quantity of tokens to stake
   */
  modifier checkStakeState(uint256 _id, uint256 amount) {
    require(block.timestamp >= stakePool[_id].startTime && block.timestamp <= stakePool[_id].endTime, "Invalid time for staking");
    require(amount > 0, "Invalid stake amount");
    _;
  }

  /**
   * @dev To validate status of rewards claiming time for a stake pool
   * @param _id stakePool id to check
   * @param _user User's address
   */
  modifier checkClaimState(uint256 _id, address _user) {
    require(block.timestamp >= stakers[_user][_id].claimStart, "Invalid time for claiming");
    _;
  }

  /**
   * @dev To validate amount passed is always greater than zero
   * @param amount token quantity validate
   */
  modifier validAmount(uint256 amount) {
    require(amount > 0, "Amount must be greater than 0");
    _;
  }

  /**
   * @dev To deposit into a Stake pool
   * @param _id Stake pool id
   * @param amount No of tokens to stake
   */
  function stake(uint256 _id, uint256 amount) external checkPoolId(_id) checkStakeState(_id, amount) returns (bool) {
    require(!paused[_id], "Pool paused");

    StakePool storage _stakePool = stakePool[_id];

    if (stakers[_msgSender()][_id].stakedAmount > 0) {
      stakers[_msgSender()][_id].stakedAmount += (amount * _stakePool.stakeBaseDecimals);
    } else {
      stakers[_msgSender()][_id] = Staker((amount * _stakePool.stakeBaseDecimals), 0, _stakePool.vestingStartTime + _stakePool.vestingCliff);
    }

    //update the staked tokens
    _stakePool.tokensStaked += amount;

    //send greenlers to stake vault
    uint256 amountToStake = amount * (10**stakePool[_id].stakeBaseDecimals);

    require(amountToStake <= IERC20(stakePool[_id].stakeToken).allowance(_msgSender(), address(this)), "Make sure to add enough allowance");

    bool status = IERC20(stakePool[_id].stakeToken).transferFrom(_msgSender(), address(this), amountToStake);

    require(status, "Token Stake failed");

    emit TokensStaked(_msgSender(), _id, amount, block.timestamp);

    return true;
  }

  /**
   * @dev Helper function to calculate the percent of a staked amount in the total reward of a stake pool
   * @param _stakedAmount art of the whole you want to calculate the percentage for
   * @param _totalStaked the whole or total value
   */
  function calculatePercentage(uint256 _stakedAmount, uint256 _totalStaked) internal view returns (uint256) {
    require(_stakedAmount != 0, "stakedAmount cannot be zero");

    uint256 fraction = (_stakedAmount * BASE_MULTIPLIER * 100) / _totalStaked; // Calculate fraction: (A / B) * 100 * 10^18
    uint256 percentage = fraction / BASE_MULTIPLIER; // Divide by 10^18 to get the percentage

    return percentage;
  }

  /**
   * @dev To get total tokens user can claim for a given stake pool based on their contributions after the pool rewards have been updated.
   * @param user User address
   * @param _id StakePool id
   */
  function tokenRewards(address user, uint256 _id) public view checkPoolId(_id) returns (uint256) {
    require(stakePool[_id].rewardAmount > 0, "Stake pool reward amount not added yet");

    Staker memory _user = stakers[user][_id];

    uint256 amount = (_user.stakedAmount - _user.claimedAmount) / (stakePool[_id].stakeBaseDecimals);

    uint256 rewardPercent = calculatePercentage(amount, stakePool[_id].tokensStaked);

    uint256 stakeReward = (stakePool[_id].rewardAmount * rewardPercent) / 100;

    return stakeReward;
  }

  /**
   * @dev Helper funtion to get withdrawable tokens for a given stake pool
   * @param user User address
   * @param _id StakePool id
   * @param _withdrawAmount Amount to withdraw
   */
  function _withdrawableAmount(
    address user,
    uint256 _id,
    uint256 _withdrawAmount
  ) internal view checkPoolId(_id) returns (uint256) {
    Staker memory _user = stakers[user][_id];

    require(_user.stakedAmount > 0, "Nothing to withdraw");

    uint256 amount = _user.stakedAmount - (_withdrawAmount * stakePool[_id].stakeBaseDecimals);
    require(amount > 0, "Withdraw amount exceeds the withdrawable amount");

    // if (block.timestamp < _user.claimStart) return 0;

    uint256 stakeWithdraw = _withdrawAmount * (10**stakePool[_id].stakeBaseDecimals);

    return stakeWithdraw;
  }

  /**
   * @dev Internsl helper function to withdraw staked tokens from a pool
   * @param _id StakePool id
   * @param _user User address
   * @param _withdrawAmount Amount to withdraw
   */
  function _withdraw(
    uint256 _id,
    address _user,
    uint256 _withdrawAmount
  ) internal validAmount(_withdrawAmount) returns (bool) {
    Staker storage user = stakers[_user][_id];

    uint256 withdrawableAmount_ = _withdrawableAmount(_user, _id, _withdrawAmount);

    require(_withdrawAmount <= withdrawableAmount_, "Withdraw amount exceeds the withdrawable amount");

    require(withdrawableAmount_ <= IERC20(stakePool[_id].stakeToken).balanceOf(address(this)), "Not enough tokens in the contract");

    uint256 stakedAmount = user.stakedAmount;

    bool status = IERC20(stakePool[_id].stakeToken).transfer(_user, withdrawableAmount_);
    require(status, "Token transfer failed");

    user.stakedAmount -= _withdrawAmount * stakePool[_id].rewardBaseDecimals;

    stakePool[_id].tokensStaked -= _withdrawAmount;

    emit TokensWithdrawn(_msgSender(), _id, stakedAmount, _withdrawAmount, block.timestamp);

    return true;
  }

  /**
   * @dev Helper funtion to get claimable tokens for a given stake pool after vesting period when claimning has started.
   * @param user User's address
   * @param _id StakePool id
   */
  function claimableAmount(address user, uint256 _id) public view checkPoolId(_id) returns (uint256) {
    Staker memory _user = stakers[user][_id];

    require(_user.stakedAmount > 0, "Nothing to claim");
    uint256 amount = _user.stakedAmount - _user.claimedAmount;
    require(amount > 0, "Already claimed");

    if (block.timestamp < _user.claimStart) return 0;

    uint256 stakeReward = tokenRewards(user, _id) * (10**stakePool[_id].rewardBaseDecimals);

    return stakeReward;
  }

  /**
   * @dev To claim tokens after vesting cliff from a stake pool
   * @param _user User address
   * @param _id StakePool id
   */
  function claim(address _user, uint256 _id) public checkPoolId(_id) checkClaimState(_id, _user) returns (bool) {
    uint256 amount = claimableAmount(_user, _id);
    require(amount > 0, "Zero claim amount");
    require(amount <= IERC20(stakePool[_id].rewardToken).balanceOf(address(this)), "Not enough tokens in the contract");

    Staker memory user = stakers[_user][_id];

    //update reward balance
    stakePool[_id].rewardBalance -= tokenRewards(_user, _id);

    stakers[_user][_id].claimedAmount += user.stakedAmount;

    bool status = IERC20(stakePool[_id].rewardToken).transfer(_user, amount);
    require(status, "Token transfer failed");
    emit TokensClaimed(_user, _id, amount, block.timestamp);
    return true;
  }

  /**
   * @dev   To withdraw staked tokens from a pool
   * @param _id StakePool id
   * @param _user User address
   * @param _withdrawAmount Amount to withdraw
   */
  function withdraw(
    uint256 _id,
    address _user,
    uint256 _withdrawAmount
  ) public checkPoolId(_id) validAmount(_withdrawAmount) {
    _withdraw(_id, _user, _withdrawAmount);
  }

  /**
   * @dev To claim tokens after vesting cliff from a stake pool
   * @param users Array of user addresses
   * @param _id stakePool id
   */
  function claimMultipleAccounts(address[] calldata users, uint256 _id) external returns (bool) {
    require(users.length > 0, "Zero users length");
    for (uint256 i; i < users.length; i++) {
      require(claim(users[i], _id), "Claim failed");
    }
    return true;
  }

  /**
   * @dev To claim tokens after vesting cliff from multiple stake pools
   * @param _ids Array of Stake pool ids
   * @param _user Address of user
   */
  function claimMultipleStakePools(uint256[] calldata _ids, address _user) external returns (bool) {
    require(_ids.length > 0, "Zero users length");
    for (uint256 i; i < _ids.length; i++) {
      require(claim(_user, _ids[i]), "Claim failed");
    }
    return true;
  }

  /**
   * @dev To withdraw staked tokens from multiple stake pools
   * @param ids Array of StakePool ids
   * @param amounts Array of amonts to withdraw
   */
  function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts) public virtual {
    require(amounts.length == ids.length, "Amounts and ids length mismatch");
    require(ids.length <= stakeId, "Ids Length is Greater than Created Pools");

    for (uint256 i = 0; i < ids.length; ) {
      _withdraw(ids[i], _msgSender(), amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  //   //Use this in case Coins are sent to the contract by mistake
  function rescueETH(uint256 weiAmount) external onlyOwner {
    require(address(this).balance >= weiAmount, "insufficient Token balance");
    payable(msg.sender).transfer(weiAmount);
  }

  function rescueAnyERC20Tokens(
    address _tokenAddr,
    address _to,
    uint256 _amount
  ) public onlyOwner {
    IERC20(_tokenAddr).transfer(_to, _amount);
  }

  receive() external payable {}

  //override ownership renounce function from ownable contract
  function renounceOwnership() public pure override(Ownable) {
    revert("Unfortunately you cannot renounce Ownership of this contract!");
  }
}
