// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DAO} from "../src/DAO.sol";

contract DAOScript is Script {
    DAO public dao;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        address nzddContract = 0xE91d143072fc5e92e6445f18aa35DBd43597340c;
        dao = new DAO( nzddContract, 0, 7);

        console.log("Contract deployed at:", address(dao));

        vm.stopBroadcast();
    }
}
