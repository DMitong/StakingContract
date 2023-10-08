// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ReceiptToken is Ownable(msg.sender), ERC20("WDMitongToken", "WDMT") {
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(address(0x0), _amount);
    }
}

contract RewardToken is Ownable(msg.sender), ERC20("DMitongToken", "DMTR") {
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
