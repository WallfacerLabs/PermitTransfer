// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {PermitTransfer} from "../src/PermitTransfer.sol";

contract PermitTransferDeploymentScript is Script {
    PermitTransfer public permitTransfer;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        permitTransfer = new PermitTransfer();

        vm.stopBroadcast();
    }
}
