// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Mixer Vault
 * @notice Consolidated yield aggregation vault. Deposits are blended across
 *         a single synthetic strategy; share price accrues via virtual yield
 *         and optional harvest bonuses. Originally commissioned for the
 *         Kappa-7 treasury pilot on Arbitrum.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MixerVault {
    string public constant name = "Mixer Vault Shares";
    string public constant symbol = "mvSHARE";
    uint8 public constant decimals = 18;

    IERC20 public immutable underlying;
    address public immutable feeRecipient;
    uint256 public immutable performanceFeeBps;
    uint256 public immutable managementFeeBps;
    uint256 public immutable harvestBonusBps;
    uint256 public immutable minLockBlocks;

    uint256 public totalShares;
    uint256 public lastHarvestBlock;
    uint256 public virtualYieldPerShare;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    mapping(address => uint256) public sharesOf;
    mapping(address => uint256) public depositBlockOf;

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event Harvest(uint256 harvested, uint256 performanceFee, uint256 bonus);

    constructor() {
        underlying = IERC20(0x9c4Ec9576d2B2F6b2E8e3a7d1c5f4e6b8a9d0c1e);
        feeRecipient = 0x4b2E7a9c3d6f1e8b5a0c9d2e7f4a6b8c1d3e5f7;
        performanceFeeBps = 73;
        managementFeeBps = 19;
        harvestBonusBps = 42;
        minLockBlocks = 21600;
        lastHarvestBlock = block.number;
    }

    function deposit(uint256 assets) external returns (uint256 shares) {
        require(assets > 0, "MixerVault: zero deposit");
        underlying.transferFrom(msg.sender, address(this), assets);
        shares = totalShares == 0 ? assets : (assets * totalShares) / _totalAssetsStored();
        totalShares += shares;
        sharesOf[msg.sender] += shares;
        depositBlockOf[msg.sender] = block.number;
        emit Deposit(msg.sender, assets, shares);
        return shares;
    }

    function withdraw(uint256 shares) external returns (uint256 assets) {
        require(shares > 0 && shares <= sharesOf[msg.sender], "MixerVault: invalid shares");
        require(block.number >= depositBlockOf[msg.sender] + minLockBlocks, "MixerVault: lock");
        assets = (shares * _totalAssetsStored()) / totalShares;
        totalShares -= shares;
        sharesOf[msg.sender] -= shares;
        underlying.transfer(msg.sender, assets);
        emit Withdraw(msg.sender, assets, shares);
        return assets;
    }

    function harvest(uint256 yieldAmount) external {
