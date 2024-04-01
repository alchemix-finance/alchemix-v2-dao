// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

interface IVoter {
    // Type of gauge being created
    enum GaugeType {
        Passthrough,
        Curve
    }

    event Abstained(address indexed voter, address indexed pool, uint256 tokenId, uint256 weight);
    event AdminUpdated(address newAdmin);
    event Attach(address indexed owner, address indexed gauge, uint256 tokenId);
    event Deposit(address indexed account, address indexed gauge, uint256 tokenId, uint256 amount);
    event Detach(address indexed owner, address indexed gauge, uint256 tokenId);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event EmergencyCouncilUpdated(address newCouncil);
    event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event SetBoostMultiplier(uint256 boostMultiplier);
    event Voted(address indexed voter, address indexed pool, uint256 tokenId, uint256 weight);
    event Withdraw(address indexed account, address indexed gauge, uint256 tokenId, uint256 amount);
    event Whitelisted(address indexed whitelister, address indexed token);
    event RemovedFromWhitelist(address indexed whitelister, address indexed token);

    function veALCX() external view returns (address);

    function admin() external view returns (address);

    function emergencyCouncil() external view returns (address);

    function totalWeight() external view returns (uint256);

    function isWhitelisted(address token) external view returns (bool);

    function getPoolVote(uint256 tokenId) external view returns (address[] memory);

    /**
     * @notice Whitelist a token to be a permitted bribe token
     * @param _token address of the token
     */
    function whitelist(address _token) external;

    /**
     * @notice Remove a token from the whitelist
     * @param _token address of the token
     */
    function removeFromWhitelist(address _token) external;

    /**
     * @notice Get the maximum voting power a given veALCX can have by using FLUX
     * @param _tokenId ID of the token
     * @return uint256 Maximum voting power
     */
    function maxVotingPower(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the maximum amount of flux a given veALCX could use as a boost
     * @param _tokenId ID of the token
     * @return uint256 Maximum flux amount
     */
    function maxFluxBoost(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Set the max veALCX voting power can be boosted by with flux
     * @param _boostMultiplier BPS of boost
     * @dev Can only be called by the admin
     */
    function setBoostMultiplier(uint256 _boostMultiplier) external;

    /**
     * @notice Reset the voting status of a veALCX
     * @param _tokenId ID of the token to reset
     * @dev Can only be called by the an approved address or the veALCX owner
     * @dev Accrues any unused flux
     */
    function reset(uint256 _tokenId) external;

    /**
     * @notice Update the voting status of a veALCX to maintain the same voting status
     * @param _tokenId ID of the token to poke
     * @dev Accrues any unused flux
     */
    function poke(uint256 _tokenId) external;

    /**
     * @notice Update the voting status of multiple veALCXs to maintain the same voting status
     * @param _tokenIds Array of token IDs to poke
     * @dev Resets tokens that have expired
     */
    function pokeTokens(uint256[] memory _tokenIds) external;

    /**
     * @notice Vote on one or multiple pools for a single veALCX
     * @param _tokenId  ID of the token voting
     * @param _poolVote Array of the pools being voted
     * @param _weights  Weights of the pools
     * @param _boost    Amount of flux to boost vote by
     * @dev Can only be called once per epoch. Accrues any unused flux
     */
    function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights, uint256 _boost) external;

    /**
     * @notice Creates a gauge for a pool
     * @param _pool      Address of the pool the gauge is for
     * @param _gaugeType Type of gauge being created
     * @dev Index and receiver are votium specific parameters and should be 0 and 0xdead for other gauge types
     */
    function createGauge(address _pool, GaugeType _gaugeType) external returns (address);

    /**
     * @notice Send the distribution of emissions to the Voter contract
     * @param amount Amount of rewards being distributed
     */
    function notifyRewardAmount(uint256 amount) external;

    /**
     * @notice Distribute rewards and bribes to all gauges
     */
    function distribute() external;
}
