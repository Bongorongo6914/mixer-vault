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
