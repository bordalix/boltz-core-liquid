// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.19;

import "../EtherSwap.sol";
import "forge-std/Test.sol";

contract EtherSwapTest is Test {
    event Lockup(
        bytes32 indexed preimageHash,
        uint amount,
        address claimAddress,
        address indexed refundAddress,
        uint timelock
    );

    event Claim(bytes32 indexed preimageHash, bytes32 preimage);
    event Refund(bytes32 indexed preimageHash);

    EtherSwap internal swap = new EtherSwap();

    bytes32 internal preimage = sha256("");
    bytes32 internal preimageHash = sha256(abi.encodePacked(preimage));
    uint256 internal lockupAmount = 1 ether;
    address internal claimAddress = 0xc6A63431BB6838289a41047602902381f14fa9c9;

    receive() payable external {}

    function testCorrectVersion() external {
        assertEq(swap.version(), 2);
    }

    function testNoSendEtherWithoutFunctionSig() external {
        (bool success,) = address(swap).call{ value: 1 }("");
        require(!success);
    }

    function testHashSwapValues() external {
        uint256 timelock = block.number;
        
        assertEq(
            swap.hashValues(preimageHash, lockupAmount, claimAddress, address(this), timelock),
            keccak256(abi.encodePacked(preimageHash, lockupAmount, claimAddress, address(this), timelock))
        );
    }

    function testLockup0ValueFail() external {
        vm.expectRevert("EtherSwap: locked amount must not be zero");
        swap.lock(preimageHash, claimAddress, block.number);
    }

    function testLock() external {
        uint256 timelock = block.number;
        
        vm.expectEmit(true, true, false, true, address(swap));
        emit Lockup(preimageHash, lockupAmount, claimAddress, address(this), timelock);

        lock(timelock);
        assertEq(address(swap).balance, lockupAmount);
        assertTrue(querySwap(timelock));
    }

    function testLockWithSameHashValueFail() external {
        uint256 timelock = block.number;

        lock(timelock);

        vm.expectRevert("EtherSwap: swap exists already");
        lock(timelock);
    }

    function testClaimWithInvalidPreimageFail() external {
        uint256 timelock = block.number;

        lock(timelock);

        vm.prank(claimAddress);
        try swap.claim(sha256("incorrect"), lockupAmount, address(this), timelock) {
            fail();
        } catch Error(string memory exception) {
            assertEq(string(exception), "EtherSwap: swap has no Ether locked in the contract");
        } catch (bytes memory) {
            fail();
        }
    }

    function testClaim() external {
        uint256 timelock = block.number;
        uint256 balanceBeforeClaim = claimAddress.balance;

        lock(timelock);

        vm.prank(claimAddress);

        vm.expectEmit(true, false, false, true, address(swap));
        emit Claim(preimageHash, preimage);
        
        swap.claim(preimage, lockupAmount, address(this), timelock);

        assertFalse(querySwap(timelock));

        assertEq(address(swap).balance, 0);
        assertEq(claimAddress.balance - balanceBeforeClaim, lockupAmount);
    }

    function testClaimTwiceFail() external {
        uint256 timelock = block.number;
        
        lock(timelock);

        vm.startPrank(claimAddress);
        swap.claim(preimage, lockupAmount, address(this), timelock);

        try swap.claim(preimage, lockupAmount, address(this), timelock) {
            fail();
        } catch Error(string memory exception) {
            assertEq(string(exception), "EtherSwap: swap has no Ether locked in the contract");
        } catch (bytes memory) {
            fail();
        }
    }

    function testRefund() external {
        uint256 timelock = block.number;

        lock(timelock);

        uint256 balanceBeforeRefund = address(this).balance;

        vm.expectEmit(true, false, false, false, address(swap));
        emit Refund(preimageHash);

        swap.refund(preimageHash, lockupAmount, claimAddress, timelock);

        assertFalse(querySwap(timelock));

        assertEq(address(swap).balance, 0);
        assertEq(address(this).balance - balanceBeforeRefund, lockupAmount);
    }

    function testRefundTwiceFail() external {
        uint256 timelock = block.number;
        
        lock(timelock);

        swap.refund(preimageHash, lockupAmount, claimAddress, timelock);

        vm.expectRevert("EtherSwap: swap has no Ether locked in the contract");
        swap.refund(preimageHash, lockupAmount, claimAddress, timelock);
    }

    function testRefundNotTimedOutFail() external {
        uint256 timelock = block.number + 1;

        lock(timelock);

        vm.expectRevert("EtherSwap: swap has not timed out yet");
        swap.refund(preimageHash, lockupAmount, claimAddress, timelock);
    }

    function testLockupPrepayMinerFee() external {
        uint256 timelock = block.number;
        uint256 prepayAmount = 123000;

        vm.expectEmit(true, true, false, true, address(swap));
        emit Lockup(preimageHash, lockupAmount, claimAddress, address(this), timelock);

        swap.lockPrepayMinerfee{ value: lockupAmount + prepayAmount }(preimageHash, payable(claimAddress), timelock, prepayAmount);

        assertEq(address(swap).balance, lockupAmount);
        assertEq(claimAddress.balance, prepayAmount);

        assertTrue(querySwap(timelock));
    }

    function testLockupPrepayMinerFeeGtValueFail() external {
        vm.expectRevert("EtherSwap: sent amount must be greater than the prepay amount");
        swap.lockPrepayMinerfee{ value: 1 }(preimageHash, payable(claimAddress), block.number, 2);
    }

    function testLockupPrepayMinerFeeEqValueFail() external {
        vm.expectRevert("EtherSwap: sent amount must be greater than the prepay amount");
        swap.lockPrepayMinerfee{ value: 1 }(preimageHash, payable(claimAddress), block.number, 1);
    }

    function lock(uint256 timelock) internal {
        swap.lock{ value: lockupAmount }(preimageHash, claimAddress, timelock);
    }

    function querySwap(uint256 timelock) internal view returns (bool) {
        return swap.swaps(
            swap.hashValues(preimageHash, lockupAmount, claimAddress, address(this), timelock)
        );
    }
}