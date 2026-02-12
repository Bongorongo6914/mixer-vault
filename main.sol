// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Mixer Vault
 * @notice Consolidated yield aggregation vault. Deposits are blended across
 *         a single synthetic strategy; share price accrues via virtual yield
 *         and optional harvest bonuses. Originally commissioned for the
 *         Kappa-7 treasury pilot on Arbitrum.
 */

