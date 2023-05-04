// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.15;

import "src/interfaces/IVotingEscrow.sol";
import "src/interfaces/IWETH9.sol";
import "src/interfaces/IRewardsDistributor.sol";
import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/balancer/WeightedPoolUserData.sol";
import "src/interfaces/balancer/IBasePool.sol";
import "src/interfaces/balancer/IAsset.sol";
import "src/interfaces/balancer/IManagedPool.sol";
import "src/interfaces/chainlink/AggregatorV3Interface.sol";
import "src/libraries/Math.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { WeightedMath } from "src/interfaces/balancer/WeightedMath.sol";

/**
 * @title  Rewards Distributor
 * @notice Contract to facilitate distribution of rewards to veALCX holders
 */
contract RewardsDistributor is IRewardsDistributor {
    using SafeERC20 for IERC20;

    uint256 public constant WEEK = 7 * 86400;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant BPS = 10000;

    bytes32 public balancerPoolId;

    uint256 public startTime;
    uint256 public timeCursor;
    uint256 public lastTokenTime;
    uint256 public tokenLastBalance;

    address public votingEscrow;
    address public rewardsToken;
    address public lockedToken;
    address public depositor;

    uint256[1000000000000000] public veSupply;
    uint256[1000000000000000] public tokensPerWeek;

    mapping(uint256 => uint256) public timeCursorOf;
    mapping(uint256 => uint256) public userEpochOf;

    IWETH9 public WETH;
    IVault public balancerVault;
    IBasePool public balancerPool;
    AggregatorV3Interface public priceFeed;
    IAsset[] public poolAssets = new IAsset[](2);

    constructor(address _votingEscrow, address _weth, address _balancerVault, address _priceFeed) {
        uint256 _t = (block.timestamp / WEEK) * WEEK;
        startTime = _t;
        lastTokenTime = _t;
        timeCursor = _t;
        rewardsToken = address(IVotingEscrow(_votingEscrow).ALCX());
        lockedToken = address(IVotingEscrow(_votingEscrow).BPT());
        votingEscrow = _votingEscrow;
        WETH = IWETH9(_weth);
        balancerVault = IVault(_balancerVault);
        balancerPool = IBasePool(address(lockedToken));
        balancerPoolId = balancerPool.getPoolId();
        priceFeed = AggregatorV3Interface(_priceFeed);
        depositor = msg.sender;
        IERC20(lockedToken).approve(_votingEscrow, type(uint256).max);
        IERC20(rewardsToken).approve(address(balancerVault), type(uint256).max);
        WETH.approve(address(balancerVault), type(uint256).max);
        poolAssets[0] = IAsset(address(WETH));
        poolAssets[1] = IAsset(rewardsToken);
    }

    /// @dev Allows for payments from the WETH contract.
    receive() external payable {
        if (IWETH9(msg.sender) != WETH) {
            revert("msg.sender is not WETH contract");
        }
    }

    /*
        View functions
    */

    function timestamp() external view returns (uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

    function veForAt(uint256 _tokenId, uint256 _timestamp) external view returns (uint256) {
        address ve = votingEscrow;
        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 epoch = _findTimestampUserEpoch(ve, _tokenId, _timestamp, maxUserEpoch);
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(_tokenId, epoch);
        return Math.max(uint256(pt.bias - pt.slope * (int256(_timestamp - pt.ts))), 0);
    }

    /// @inheritdoc IRewardsDistributor
    function claimable(uint256 _tokenId) external view returns (uint256) {
        uint256 _lastTokenTime = (lastTokenTime / WEEK) * WEEK;
        return _claimable(_tokenId, votingEscrow, _lastTokenTime);
    }

    /// @inheritdoc IRewardsDistributor
    function amountToCompound(uint256 _alcxAmount) public view returns (uint256, uint256[] memory) {
        (uint80 roundId, int256 alcxEthPrice, , uint256 priceTimestamp, uint80 answeredInRound) = priceFeed
            .latestRoundData();

        require(answeredInRound >= roundId, "Stale price");
        require(priceTimestamp != 0, "Round not complete");
        require(alcxEthPrice > 0, "Chainlink answer reporting 0");

        uint256[] memory normalizedWeights = IManagedPool(address(balancerPool)).getNormalizedWeights();

        uint256 amount = (((_alcxAmount * uint256(alcxEthPrice)) / 1 ether) * normalizedWeights[0]) /
            normalizedWeights[1];

        return (amount, normalizedWeights);
    }

    /*
        External functions
    */

    /**
     * @notice
     */
    function checkpointToken() external {
        assert(msg.sender == depositor);
        _checkpointToken();
    }

    function checkpointTotalSupply() external {
        _checkpointTotalSupply();
    }

    /// @inheritdoc IRewardsDistributor
    function claim(uint256 _tokenId, bool _compound) external payable returns (uint256) {
        bool approvedOrOwner = IVotingEscrow(votingEscrow).isApprovedOrOwner(msg.sender, _tokenId);
        bool isVotingEscrow = msg.sender == votingEscrow;

        require(approvedOrOwner || isVotingEscrow, "not approved");

        address owner = IVotingEscrow(votingEscrow).ownerOf(_tokenId);

        if (block.timestamp >= timeCursor) _checkpointTotalSupply();
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;

        uint256 alcxAmount = _claim(_tokenId, votingEscrow, _lastTokenTime);

        // Return 0 without reverting if there are no rewards
        if (alcxAmount == 0) return alcxAmount;

        tokenLastBalance -= alcxAmount;

        if (_compound) {
            (uint256 wethAmount, uint256[] memory normalizedWeights) = amountToCompound(alcxAmount);

            require(
                msg.value >= wethAmount || WETH.balanceOf(msg.sender) >= wethAmount,
                "insufficient balance to compound"
            );

            // Wrap eth if necessary
            if (msg.value > 0) WETH.deposit{ value: msg.value }();
            else IERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), wethAmount);

            _depositIntoBalancerPool(wethAmount, alcxAmount, normalizedWeights);

            IVotingEscrow(votingEscrow).depositFor(_tokenId, IERC20(lockedToken).balanceOf(address(this)));

            return alcxAmount;
        } else {
            // The fee amount stays in the contract effectively redistributing it to veALCX holders
            // If VotingEscrow contract is calling claim it is because veALCX is unlocked and there is no fee
            uint256 feeAmount = isVotingEscrow ? 0 : (alcxAmount * IVotingEscrow(votingEscrow).claimFeeBps()) / BPS;

            uint256 claimAmount = alcxAmount - feeAmount;

            // Transfer rewards to veALCX owner
            IERC20(rewardsToken).safeTransfer(owner, claimAmount);

            return claimAmount;
        }
    }

    /// @dev Once off event on contract initialize
    function setDepositor(address _depositor) external {
        require(msg.sender == depositor);
        depositor = _depositor;
    }

    /*
        Internal functions
    */

    /**
     * @notice Record data to checkpoint
     * @dev Records veALCX holder rewards over time
     */
    function _checkpointToken() internal {
        uint256 tokenBalance = IERC20(rewardsToken).balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 thisWeek = (t / WEEK) * WEEK;
        uint256 nextWeek = 0;

        for (uint256 i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (block.timestamp - t)) / sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (nextWeek - t)) / sinceLast;
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    function _findTimestampEpoch(address ve, uint256 _timestamp) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = IVotingEscrow(ve).epoch();
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).pointHistory(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findTimestampUserEpoch(
        address ve,
        uint256 tokenId,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = maxUserEpoch;
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(tokenId, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /**
     * @notice Record global data to a checkpoint
     */
    function _checkpointTotalSupply() internal {
        address ve = votingEscrow;
        uint256 t = timeCursor;
        uint256 roundedTimestamp = (block.timestamp / WEEK) * WEEK;
        IVotingEscrow(ve).checkpoint();

        for (uint256 i = 0; i < 20; i++) {
            if (t > roundedTimestamp) {
                break;
            } else {
                uint256 epoch = _findTimestampEpoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).pointHistory(epoch);
                int256 dt = 0;
                if (t > pt.ts) {
                    dt = int256(t - pt.ts);
                }
                veSupply[t] = Math.max(uint256(pt.bias - pt.slope * dt), 0);
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    /**
     * @notice Get the amount of ALCX rewards a veALCX has earned
     * @param _tokenId ID of the token
     * @param _ve veALCX address
     * @param _lastTokenTime Point in time of veALCX rewards accrual
     * @return uint256 Amount of ALCX rewards claimable
     */
    function _claim(uint256 _tokenId, address _ve, uint256 _lastTokenTime) internal returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(_ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(_ve, _tokenId, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory userPoint = IVotingEscrow(_ve).userPointHistory(_tokenId, userEpoch);

        if (weekCursor == 0) weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;
        if (weekCursor >= lastTokenTime) return 0;
        if (weekCursor < _startTime) weekCursor = _startTime;

        IVotingEscrow.Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;
                if (userEpoch > maxUserEpoch) {
                    userPoint = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    userPoint = IVotingEscrow(_ve).userPointHistory(_tokenId, userEpoch);
                }
            } else {
                int256 dt = int256(weekCursor - oldUserPoint.ts);
                uint256 balanceOf = Math.max(uint256(oldUserPoint.bias - dt * oldUserPoint.slope), 0);
                if (balanceOf == 0 && userEpoch > maxUserEpoch) break;
                if (balanceOf != 0) {
                    toDistribute += (balanceOf * tokensPerWeek[weekCursor]) / veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[_tokenId] = userEpoch;
        timeCursorOf[_tokenId] = weekCursor;

        emit Claimed(_tokenId, toDistribute, userEpoch, maxUserEpoch);

        return toDistribute;
    }

    function _claimable(uint256 _tokenId, address _ve, uint256 _lastTokenTime) internal view returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(_ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(_ve, _tokenId, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory userPoint = IVotingEscrow(_ve).userPointHistory(_tokenId, userEpoch);

        if (weekCursor == 0) weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;
        if (weekCursor >= lastTokenTime) return 0;
        if (weekCursor < _startTime) weekCursor = _startTime;

        IVotingEscrow.Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;
                if (userEpoch > maxUserEpoch) {
                    userPoint = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    userPoint = IVotingEscrow(_ve).userPointHistory(_tokenId, userEpoch);
                }
            } else {
                int256 dt = int256(weekCursor - oldUserPoint.ts);
                uint256 balanceOf = Math.max(uint256(oldUserPoint.bias - dt * oldUserPoint.slope), 0);
                if (balanceOf == 0 && userEpoch > maxUserEpoch) break;
                if (balanceOf != 0) {
                    toDistribute += (balanceOf * tokensPerWeek[weekCursor]) / veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        return toDistribute;
    }

    /**
     * @notice Claim ALCX rewards for a given veALCX position
     * @param _wethAmount Amount of WETH to deposit into pool
     * @param _alcxAmount Amount of ALCX to deposit into pool
     * @param _normalizedWeights Weight of ALCX and WETH
     */
    function _depositIntoBalancerPool(
        uint256 _wethAmount,
        uint256 _alcxAmount,
        uint256[] memory _normalizedWeights
    ) internal {
        (, uint256[] memory balances, ) = balancerVault.getPoolTokens(balancerPoolId);

        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = _wethAmount;
        amountsIn[1] = _alcxAmount;

        uint256 bptAmountOut = WeightedMath._calcBptOutGivenExactTokensIn(
            balances,
            _normalizedWeights,
            amountsIn,
            IERC20(address(balancerPool)).totalSupply(),
            balancerPool.getSwapFeePercentage()
        );

        bytes memory _userData = abi.encode(
            WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            bptAmountOut
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: poolAssets,
            maxAmountsIn: amountsIn,
            userData: _userData,
            fromInternalBalance: false
        });

        balancerVault.joinPool(balancerPoolId, address(this), address(this), request);
    }
}
