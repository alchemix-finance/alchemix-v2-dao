// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./libraries/Math.sol";
import "./interfaces/IERC20.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";
import "./interfaces/IVotingEscrow.sol";
import { IVault } from "./interfaces/balancer/IVault.sol";
import { WeightedPoolUserData } from "./interfaces/balancer/WeightedPoolUserData.sol";
import { IBasePool } from "./interfaces/balancer/IBasePool.sol";
import { IAsset } from "./interfaces/balancer/IAsset.sol";

contract RewardsDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(uint256 tokenId, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    uint256 constant WEEK = 7 * 86400;
    uint256 constant CLAIM_FEE = 2;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IWETH9 public WETH;
    IVault public balancerVault;
    bytes32 public balancerPoolId;

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
        address _balancerVault
    ) {
        uint256 _t = (block.timestamp / WEEK) * WEEK;
        startTime = _t;
        lastTokenTime = _t;
        timeCursor = _t;
        address _rewardsToken = IVotingEscrow(_votingEscrow).ALCX();
        address _lockedToken = IVotingEscrow(_votingEscrow).BPT();
        rewardsToken = _rewardsToken;
        lockedToken = _lockedToken;
        votingEscrow = _votingEscrow;
        WETH = IWETH9(_weth);
        balancerVault = IVault(_balancerVault);
        balancerPoolId = IBasePool(address(lockedToken)).getPoolId();
        depositor = msg.sender;
        IERC20(_lockedToken).approve(_votingEscrow, type(uint256).max);
        IERC20(_rewardsToken).approve(address(balancerVault), type(uint256).max);
        WETH.approve(address(balancerVault), type(uint256).max);
        poolAssets[0] = IAsset(address(WETH));
        poolAssets[1] = IAsset(address(_rewardsToken));
    }

    /// @dev Allows for payments from the WETH contract.
    // receive() external payable {
    //     if (IWETH9(msg.sender) != WETH) {
    //         revert("msg.sender is not WETH contract");
    //     }
    // }

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
        address ve,
        uint256 _lastTokenTime
    ) internal returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(ve, _tokenId, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory userPoint = IVotingEscrow(ve).userPointHistory(_tokenId, userEpoch);

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
                    userPoint = IVotingEscrow(ve).userPointHistory(_tokenId, userEpoch);
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
        address ve,
        uint256 _lastTokenTime
    ) internal view returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(_tokenId);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[_tokenId];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(ve, _tokenId, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVotingEscrow.Point memory userPoint = IVotingEscrow(ve).userPointHistory(_tokenId, userEpoch);

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
                    userPoint = IVotingEscrow(ve).userPointHistory(_tokenId, userEpoch);
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

    function _depositIntoBalancerPool(uint256 _wethAmount, uint256 _alcxAmount) internal {
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = _wethAmount;
        amountsIn[1] = _alcxAmount;

        uint256 amountOut = 0; // bpt amount out calc

        bytes memory _userData = abi.encode(
            WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            amountOut
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

        require(alcxAmount >= 0, "nothing to claim");

        tokenLastBalance -= alcxAmount;

        if (_compound) {
            uint256 wethAmount = alcxAmount / 8; // Do weth % calc here

            require(
                msg.value == wethAmount || WETH.balanceOf(msg.sender) >= wethAmount,
                "insufficient eth to compound"
            );

            // Wrap eth if necessary
            if (msg.value > 0) WETH.deposit{ value: msg.value }();
            else WETH.transferFrom(msg.sender, address(this), wethAmount);

            _depositIntoBalancerPool(wethAmount, alcxAmount);

            IVotingEscrow(votingEscrow).depositFor(_tokenId, IERC20(lockedToken).balanceOf(address(this)));

            return alcxAmount;
        }

        uint256 claimAmount = alcxAmount / CLAIM_FEE;
        uint256 burnAmount = alcxAmount - claimAmount;

        IERC20(rewardsToken).transfer(BURN_ADDRESS, burnAmount);
        IERC20(rewardsToken).transfer(owner, claimAmount);

        return claimAmount;
    }

    // Once off event on contract initialize
    function setDepositor(address _depositor) external {
        require(msg.sender == depositor);
        depositor = _depositor;
    }
}
