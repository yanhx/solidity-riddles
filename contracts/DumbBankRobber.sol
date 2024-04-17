pragma solidity 0.8.15;

import "hardhat/console.sol";

contract DumbBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender], "not enough funds");
        console.log("T", address(this).balance);
        (bool ok,) = msg.sender.call{value: amount}("");
        console.log("T1", address(this).balance);
        require(ok, "BBB");
        unchecked {
            balances[msg.sender] -= amount;
        }
    }
}

interface IDumbBank {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// This attack fails. Make the attack succeed.
contract BankRobber {
    IDumbBank dumbBank;

    constructor(IDumbBank _dumbBank) payable {
        dumbBank = _dumbBank;
        _dumbBank.deposit{value: 1 ether}();
        _dumbBank.withdraw(1 ether);
    }

    fallback() external payable {
        console.log("T2", address(this).balance);
        if (address(dumbBank).balance > 1 ether) {
            dumbBank.withdraw(1 ether);
        }
    }
}
