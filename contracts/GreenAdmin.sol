// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GreenlersAdmin is ReentrancyGuard, Ownable {
  uint256 public saleId;
  uint256 public BASE_MULTIPLIER;

  struct Sale {
    address saleToken;
    uint256 buyPrice;
    uint256 sellPrice;
    uint256 tokensToSell;
    uint256 baseDecimals;
    uint256 inSale;
    uint256 enableBuyWithEth;
    uint256 enableBuyWithUsdt;
    address payout;
  }

  IERC20 public USDTInterface;
  AggregatorV3Interface internal aggregatorInterface; // https://docs.chain.link/docs/ethereum-addresses/ => (BNB / USD)

  mapping(uint256 => bool) public paused;
  mapping(uint256 => Sale) public sale;

  event SaleCreated(uint256 indexed _id, uint256 _totalTokens, uint256 enableBuyWithEth, uint256 enableBuyWithUsdt, address _payout);

  event SaleUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);

  event TokensTransacted(
    bytes32 key,
    address indexed user,
    uint256 indexed id,
    address indexed purchaseToken,
    uint256 tokensBought,
    uint256 amountPaid,
    uint256 timestamp
  );

  event SaleTokenAddressUpdated(address indexed prevValue, address indexed newValue, uint256 timestamp);

  event SalePayoutAddressUpdated(address indexed prevValue, address indexed newValue, uint256 timestamp);

  event SalePaused(uint256 indexed id, uint256 timestamp);
  event SaleUnpaused(uint256 indexed id, uint256 timestamp);

  /**
   * @dev Initializes the contract and sets key parameters
   * @param _oracle Oracle contract to fetch ETH/USDT price
   * @param _usdt USDT token contract address
   */
  constructor(address _oracle, address _usdt) {
    require(_oracle != address(0), "Zero aggregator address");
    require(_usdt != address(0), "Zero USDT address");

    aggregatorInterface = AggregatorV3Interface(_oracle);
    USDTInterface = IERC20(_usdt);
    BASE_MULTIPLIER = (10**18);
  }

  /**
   * @dev Creates a new sale
   * @param _saleTokenAddress Sale token address
   * @param _buyPrice Per token price multiplied by (10**18)
   * @param _sellPrice Per token price multiplied by (10**18)
   * @param _tokensToSell No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
   * @param _baseDecimals No of decimals for the token. (10**18), for 18 decimal token
   * @param _enableBuyWithEth Enable/Disable buy of tokens with ETH
   * @param _enableBuyWithUsdt Enable/Disable buy of tokens with USDT
   * @param _payout Ethereum address where sale contributions will be moved
   */
  function createSale(
    address _saleTokenAddress,
    uint256 _buyPrice,
    uint256 _sellPrice,
    uint256 _tokensToSell,
    uint256 _baseDecimals,
    uint256 _enableBuyWithEth,
    uint256 _enableBuyWithUsdt,
    address _payout
  ) external onlyOwner {
    require(_buyPrice > 0, "Zero price");
    require(_sellPrice > 0, "Zero price");
    require(_tokensToSell > 0, "Zero tokens to sell");
    require(_baseDecimals > 0, "Zero decimals for the token");

    saleId++;

    sale[saleId] = Sale(_saleTokenAddress, _buyPrice, _sellPrice, _tokensToSell, _baseDecimals, _tokensToSell, _enableBuyWithEth, _enableBuyWithUsdt, _payout);

    emit SaleCreated(saleId, _tokensToSell, _enableBuyWithEth, _enableBuyWithUsdt, _payout);
  }

  /**
   * @dev To update the oracle address address
   * @param _newAddress oracle address
   */

  function changeOracleAddress(address _newAddress) external onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    aggregatorInterface = AggregatorV3Interface(_newAddress);
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
   * @dev To update the sale token address
   * @param _id Sale id to update
   * @param _newAddress Sale token address
   */
  function changeSaleTokenAddress(uint256 _id, address _newAddress) external checkSaleId(_id) onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    address prevValue = sale[_id].saleToken;
    sale[_id].saleToken = _newAddress;
    emit SaleTokenAddressUpdated(prevValue, _newAddress, block.timestamp);
  }

  /**
   * @dev To update the payout address
   * @param _id Sale id to update
   * @param _newAddress payout address
   */
  function changePayoutAddress(uint256 _id, address _newAddress) external checkSaleId(_id) onlyOwner {
    require(_newAddress != address(0), "Zero token address");
    address prevValue = sale[_id].payout;
    sale[_id].payout = _newAddress;
    emit SalePayoutAddressUpdated(prevValue, _newAddress, block.timestamp);
  }

  /**
   * @dev To update the buy price
   * @param _id Sale id to update
   * @param _newPrice New buy price of the token
   */
  function changeBuyPrice(uint256 _id, uint256 _newPrice) external checkSaleId(_id) onlyOwner {
    require(_newPrice > 0, "Zero price");
    uint256 prevValue = sale[_id].buyPrice;
    sale[_id].buyPrice = _newPrice;
    emit SaleUpdated(bytes32("BUY"), prevValue, _newPrice, block.timestamp);
  }

  /**
   * @dev To update the sell price
   * @param _id Sale id to update
   * @param _newPrice New sell price of the token
   */
  function changeSellPrice(uint256 _id, uint256 _newPrice) external checkSaleId(_id) onlyOwner {
    require(_newPrice > 0, "Zero price");
    uint256 prevValue = sale[_id].sellPrice;
    sale[_id].sellPrice = _newPrice;
    emit SaleUpdated(bytes32("SELL"), prevValue, _newPrice, block.timestamp);
  }

  /**
   * @dev To update possibility to buy with ETH
   * @param _id Sale id to update
   * @param _enableToBuyWithEth New value of enable to buy with ETH
   */
  function changeEnableBuyWithEth(uint256 _id, uint256 _enableToBuyWithEth) external checkSaleId(_id) onlyOwner {
    uint256 prevValue = sale[_id].enableBuyWithEth;
    sale[_id].enableBuyWithEth = _enableToBuyWithEth;
    emit SaleUpdated(bytes32("ENABLE_BUY_WITH_ETH"), prevValue, _enableToBuyWithEth, block.timestamp);
  }

  /**
   * @dev To update possibility to buy with Usdt
   * @param _id Sale id to update
   * @param _enableToBuyWithUsdt New value of enable to buy with Usdt
   */
  function changeEnableBuyWithUsdt(uint256 _id, uint256 _enableToBuyWithUsdt) external checkSaleId(_id) onlyOwner {
    uint256 prevValue = sale[_id].enableBuyWithUsdt;
    sale[_id].enableBuyWithUsdt = _enableToBuyWithUsdt;
    emit SaleUpdated(bytes32("ENABLE_BUY_WITH_USDT"), prevValue, _enableToBuyWithUsdt, block.timestamp);
  }

  /**
   * @dev To pause the sale
   * @param _id Sale id to update
   */
  function pauseSale(uint256 _id) external checkSaleId(_id) onlyOwner {
    require(!paused[_id], "Already paused");
    paused[_id] = true;
    emit SalePaused(_id, block.timestamp);
  }

  /**
   * @dev To unpause the sale
   * @param _id Sale id to update
   */
  function unPauseSale(uint256 _id) external checkSaleId(_id) onlyOwner {
    require(paused[_id], "Not paused");
    paused[_id] = false;
    emit SaleUnpaused(_id, block.timestamp);
  }

  /**
   * @dev To get latest ethereum price in 10**18 format
   */
  function getLatestPrice() public view returns (uint256) {
    (, int256 price, , , ) = aggregatorInterface.latestRoundData();
    price = (price * (10**10));
    return uint256(price);
  }

  modifier checkSaleId(uint256 _id) {
    require(_id > 0 && _id <= saleId, "Invalid sale id");
    _;
  }

  /**
   * @dev To buy into a sale using USDT
   * @param _id Sale id
   * @param amount No of tokens to buy
   */
  function buyWithUSDT(uint256 _id, uint256 amount) external checkSaleId(_id) returns (bool) {
    require(amount > 0, "Zero claim amount");
    require(sale[_id].saleToken != address(0), "Sale token address not set");
    require(!paused[_id], "Sale paused");
    require(sale[_id].enableBuyWithUsdt > 0, "Not allowed to buy with USDT");
    uint256 usdPrice = amount * sale[_id].buyPrice;
    sale[_id].inSale -= amount;

    Sale memory _sale = sale[_id];

    uint256 ourAllowance = USDTInterface.allowance(_msgSender(), address(this));
    require(usdPrice <= ourAllowance, "Make sure to add enough allowance");
    (bool success, ) = address(USDTInterface).call(
      abi.encodeWithSignature("transferFrom(address,address,uint256)", _msgSender(), _sale.payout, usdPrice)
    );
    require(success, "Token payment failed");

    //send token to user wallet
    uint256 amountToClaim = amount * (10**sale[_id].baseDecimals);

    bool status = IERC20(sale[_id].saleToken).transfer(_msgSender(), amountToClaim);

    require(status, "Token transfer failed");

    emit TokensTransacted(bytes32("BOUGHT"), _msgSender(), _id, address(USDTInterface), amount, usdPrice, block.timestamp);

    return true;
  }

  /**
   * @dev To buy into a sale using ETH
   * @param _id Sale id
   * @param amount No of tokens to buy
   */
  function buyWithEth(uint256 _id, uint256 amount) external payable checkSaleId(_id) nonReentrant returns (bool) {
    require(amount > 0, "Zero claim amount");
    require(sale[_id].saleToken != address(0), "Sale token address not set");
    require(!paused[_id], "Sale paused");
    require(sale[_id].enableBuyWithEth > 0, "Not allowed to buy with ETH");
    uint256 usdPrice = amount * sale[_id].buyPrice;
    uint256 ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
    require(msg.value >= ethAmount, "Less payment");
    uint256 excess = msg.value - ethAmount;
    sale[_id].inSale -= amount;
    Sale memory _sale = sale[_id];

    //send token price to admin wallet
    sendValue(payable(_sale.payout), ethAmount);

    //send token to user wallet
    uint256 amountToClaim = amount * (10**sale[_id].baseDecimals);

    require(amountToClaim <= IERC20(sale[_id].saleToken).balanceOf(address(this)), "Not enough tokens in the contract");

    bool status = IERC20(sale[_id].saleToken).transfer(_msgSender(), amountToClaim);

    require(status, "Token transfer failed");

    if (excess > 0) sendValue(payable(_msgSender()), excess);

    emit TokensTransacted(bytes32("BOUGHT"), _msgSender(), _id, address(0), amount, ethAmount, block.timestamp);

    return true;
  }

  /**
   * @dev To swap Greenlers token for equivalent Eth
   * @param _id Sale id
   * @param amount No of tokens to sell
   */
  function sellGreenForEth(uint256 _id, uint256 amount) external checkSaleId(_id) nonReentrant returns (bool) {
    require(amount > 0, "Zero claim amount");
    require(sale[_id].saleToken != address(0), "Sale token address not set");
    require(!paused[_id], "Sale paused");
    // require(sale[_id].enableBuyWithEth > 0, "Not allowed to buy with ETH");
    uint256 usdPrice = amount * sale[_id].sellPrice;
    uint256 ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();

    //send greenlers to admin wallet
    sendValue(payable(_msgSender()), ethAmount);

    //send token to user wallet
    uint256 amountToSell = amount * (10**sale[_id].baseDecimals);

    require(amountToSell <= IERC20(sale[_id].saleToken).allowance(_msgSender(), address(this)), "Make sure to add enough allowance");

    bool status = IERC20(sale[_id].saleToken).transferFrom(_msgSender(), address(this), amountToSell);

    require(status, "Token transfer failed");

    emit TokensTransacted(bytes32("SOLD"), _msgSender(), _id, address(0), amount, ethAmount, block.timestamp);

    return true;
  }

  /**
   * @dev To swap Greenlers token for equivalent Eth
   * @param _id Sale id
   * @param amount No of tokens to sell
   */
  function sellGreenForUSD(uint256 _id, uint256 amount) external checkSaleId(_id) nonReentrant returns (bool) {
    require(amount > 0, "Zero claim amount");
    require(sale[_id].saleToken != address(0), "Sale token address not set");
    require(!paused[_id], "Sale paused");
    // require(sale[_id].enableBuyWithUsdt > 0, "Not allowed to buy with USDT");
    uint256 usdPrice = amount * sale[_id].sellPrice;
    sale[_id].inSale += amount;

    //send greenlers to admin wallet
    uint256 amountToSell = amount * (10**sale[_id].baseDecimals);

    require(amountToSell <= IERC20(sale[_id].saleToken).allowance(_msgSender(), address(this)), "Make sure to add enough allowance");

    bool status = IERC20(sale[_id].saleToken).transferFrom(_msgSender(), address(this), amountToSell);
    
    require(status, "Token payment failed");
    
    require(usdPrice <= USDTInterface.balanceOf(address(this)), "Not usdt enough tokens in the contract");

    (bool success, ) = address(USDTInterface).call(
      abi.encodeWithSignature("transfer(address,uint256)", _msgSender(), usdPrice)
    );

    require(success, "Token transfer failed");

    emit TokensTransacted(bytes32("SOLD"), _msgSender(), _id, address(USDTInterface), amount, usdPrice, block.timestamp);

    return true;
  }

  /**
   * @dev Helper funtion to get ETH price for given amount
   * @param _id Sale id
   * @param amount No of tokens to buy
   */
  function ethBuyHelper(uint256 _id, uint256 amount) external view checkSaleId(_id) returns (uint256 ethAmount) {
    uint256 usdPrice = amount * sale[_id].buyPrice;
    ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
  }

  /**
   * @dev Helper funtion to get ETH price for given amount
   * @param _id Sale id
   * @param amount No of tokens to sell
   */
  function ethSellHelper(uint256 _id, uint256 amount) external view checkSaleId(_id) returns (uint256 ethAmount) {
    uint256 usdPrice = amount * sale[_id].sellPrice;
    ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
  }

  /**
   * @dev Helper funtion to get USDT price for given amount
   * @param _id Sale id
   * @param amount No of tokens to buy
   */
  function usdtBuyHelper(uint256 _id, uint256 amount) external view checkSaleId(_id) returns (uint256 usdPrice) {
    usdPrice = amount * sale[_id].buyPrice;
    return usdPrice;
  }

  /**
   * @dev Helper funtion to get USDT price for given amount
   * @param _id Sale id
   * @param amount No of tokens to sell
   */
  function usdtSellHelper(uint256 _id, uint256 amount) external view checkSaleId(_id) returns (uint256 usdPrice) {
    usdPrice = amount * sale[_id].sellPrice;
    return usdPrice;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Low balance");
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "ETH Payment failed");
  }

  /**
   * @dev To get total tokens user has for a given sale round.
   * @param userAddress User address
   * @param _id Sale id
   */

  function userBalance(uint8 _id, address userAddress) public view returns (uint256) {
    uint256 balance = IERC20(sale[_id].saleToken).balanceOf(address(userAddress));

    return balance;
  }

  //Use this in case Coins are sent to the contract by mistake
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
