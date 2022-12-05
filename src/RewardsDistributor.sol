// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import { SafeERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";
import "./interfaces/IVotingEscrow.sol";
import { IVault } from "./interfaces/balancer/IVault.sol";
import { WeightedPoolUserData } from "./interfaces/balancer/WeightedPoolUserData.sol";
import { IBasePool } from "./interfaces/balancer/IBasePool.sol";
import { IAsset } from "./interfaces/balancer/IAsset.sol";
import { IManagedPool } from "./interfaces/balancer/IManagedPool.sol";
import { WeightedMath } from "./interfaces/balancer/WeightedMath.sol";
import { AggregatorV3Interface } from "./interfaces/chainlink/AggregatorV3Interface.sol";

contract RewardsDistributor {
    using SafeERC20 for IERC20;

    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(uint256 tokenId, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    uint256 constant WEEK = 7 * 86400;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant BPS = 10000;

    IWETH9 public WETH;
    IVault public balancerVault;
    bytes32 public balancerPoolId;
    IBasePool public balancerPool;
    AggregatorV3Interface public priceFeed;

    uint256 public startTime;
    uint256 public timeCursor;
    mapping(uint256 => uint256) public timeCursorOf;
    mapping(uint256 => uint256) public userEpochOf;

    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;

    address public votingEscrow;
    address public rewardsToken;
    address public lockedToken;
    uint256 public tokenLastBalance;

    uint256[1000000000000000] public veSupply;

    address public depositor;

    IAsset[] public poolAssets = new IAsset[](2);

    constructor(
        address _votingEscrow,
        address _weth,
        address _balancerVault,
        address _priceFeed
    ) {
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

    function timestamp() external view returns (uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }

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
                if (sinceLast == 0 && block.timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (block.timestamp - t)) / sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
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

    function checkpointToken() external {
        assert(msg.sender == depositor);
        _checkpointToken();
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

    function veForAt(uint256 _tokenId, uint256 _timestamp) external view returns (uint256) {
        address ve = votingEscrow;
        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 epoch = _findTimestampUserEpoch(ve, _tokenId, _timestamp, maxUserEpoch);
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).userPointHistory(_tokenId, epoch);
        return Math.max(uint256(pt.bias - pt.slope * (int256(_timestamp - pt.ts))), 0);
    }

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

    function checkpointTotalSupply() external {
        _checkpointTotalSupply();
    }

    function _claim(
        uint256 _tokenId,
        address _ve,
        uint256 _lastTokenTime
    ) internal returns (uint256) {
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

    function _claimable(
        uint256 _tokenId,
        address _ve,
        uint256 _lastTokenTime
    ) internal view returns (uint256) {
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

    function claimable(uint256 _tokenId) external view returns (uint256) {
        uint256 _lastTokenTime = (lastTokenTime / WEEK) * WEEK;
        return _claimable(_tokenId, votingEscrow, _lastTokenTime);
    }

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

    function claim(uint256 _tokenId, bool _compound) external payable returns (uint256) {
        require(IVotingEscrow(votingEscrow).isApprovedOrOwner(msg.sender, _tokenId), "not approved or owner");

        address owner = IVotingEscrow(votingEscrow).ownerOf(_tokenId);

        if (block.timestamp >= timeCursor) _checkpointTotalSupply();
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;

        uint256 alcxAmount = _claim(_tokenId, votingEscrow, _lastTokenTime);

        require(alcxAmount > 0, "nothing to claim");

        tokenLastBalance -= alcxAmount;

        if (_compound) {
            (uint256 wethAmount, uint256[] memory normalizedWeights) = amountToCompound(alcxAmount);

            require(
                msg.value >= wethAmount || WETH.balanceOf(msg.sender) >= wethAmount,
                "insufficient eth to compound"
            );

            // Wrap eth if necessary
            if (msg.value > 0) WETH.deposit{ value: msg.value }();
            else IERC20(address(WETH)).safeTransferFrom(msg.sender, address(this), wethAmount);

            _depositIntoBalancerPool(wethAmount, alcxAmount, normalizedWeights);

            IVotingEscrow(votingEscrow).depositFor(_tokenId, IERC20(lockedToken).balanceOf(address(this)));

            return alcxAmount;
        } else {
            uint256 feeAmount = (alcxAmount * IVotingEscrow(votingEscrow).claimFeeBps()) / BPS;
            uint256 claimAmount = alcxAmount - feeAmount;

            IERC20(rewardsToken).safeTransfer(BURN_ADDRESS, feeAmount);
            IERC20(rewardsToken).safeTransfer(owner, claimAmount);

            return claimAmount;
        }
    }

    // Amount of ETH or WETH required to create balanced pool deposit
    function amountToCompound(uint256 _alcxAmount) public view returns (uint256, uint256[] memory) {
        (, int256 alcxEthPrice, , , ) = priceFeed.latestRoundData();

        // Return weights to prevent extra lookups
        uint256[] memory normalizedWeights = IManagedPool(address(balancerPool)).getNormalizedWeights();

        // Amount of eth to deposit given the amount of alcx rewards and currenct price of alcx/eth
        uint256 amount = (((_alcxAmount * uint256(alcxEthPrice)) / 1 ether) * normalizedWeights[0]) /
            normalizedWeights[1];

        return (amount, normalizedWeights);
    }

    // Once off event on contract initialize
    function setDepositor(address _depositor) external {
        require(msg.sender == depositor);
        depositor = _depositor;
    }
}
