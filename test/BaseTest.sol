pragma solidity ^0.8.15;

import { DSTest } from "ds-test/test.sol";
import { DSTestPlus } from "./utils/DSTestPlus.sol";
import "src/VotingEscrow.sol";

// import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IAlchemixToken } from "src/interfaces/IAlchemixToken.sol";

abstract contract BaseTest is DSTestPlus {
    IAlchemixToken public alcx = IAlchemixToken(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    address constant admin = 0x8392F6669292fA56123F71949B52d883aE57e225;
    address account = address(0xbeef);

    function mintAlcx(uint256 _amount) public {
        hevm.startPrank(admin);

        alcx.grantRole(keccak256("MINTER"), address(admin));
        alcx.mint(account, _amount);

        hevm.stopPrank();
    }

    function approveAmount(address _spender, uint256 _amount) public {
        hevm.startPrank(account);

        alcx.approve(_spender, _amount);

        hevm.stopPrank();
    }
}
