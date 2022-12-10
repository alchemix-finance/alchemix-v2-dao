pragma solidity ^0.8.15;

interface IVoter {
    function veALCX() external view returns (address);
    function governor() external view returns (address);
    function emergencyCouncil() external view returns (address);
    function executor() external view returns (address);
    function attachTokenToGauge(uint256 _tokenId, address account) external;
    function detachTokenFromGauge(uint256 _tokenId, address account) external;
    function emitDeposit(uint256 _tokenId, address account, uint256 amount) external;
    function emitWithdraw(uint256 _tokenId, address account, uint256 amount) external;
    function notifyRewardAmount(uint256 amount) external;
    function distribute(address _gauge) external;
}
