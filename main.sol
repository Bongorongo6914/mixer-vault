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

