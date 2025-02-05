/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
// For Ethereum Sepolia
import { SepoliaZamaFHEVMConfig } from "fhevm/config/ZamaFHEVMConfig.sol";
/**
 * @notice Manages unique ID mappings between addresses and sequential IDs
 * @dev Inherits from Ownable2Step for secure ownership transfer
 */
contract IdMapping is Ownable2Step , SepoliaZamaFHEVMConfig {
    error IdAlreadyGenerated();
    error InvalidAddress();
    error IdOverflow();
    error NoIdGenerated();
    error InvalidId();
    error NoAddressFound();

    /// @notice Maps user addresses to their unique IDs
    mapping(address => uint256) public addressToId;
    /// @dev Maps unique IDs back to user addresses
    mapping(uint256 => address) private idToAddress;

    uint256 private nextId = 1;

    event IdGenerated(address indexed user, uint256 indexed id);

    constructor() Ownable(msg.sender) {
        nextId = 1;
    }

    function generateId() public returns (uint256) {
        if (addressToId[msg.sender] != 0) revert IdAlreadyGenerated();
        if (msg.sender == address(0)) revert InvalidAddress();

        uint256 newId = nextId;

        addressToId[msg.sender] = newId;
        idToAddress[newId] = msg.sender;
        nextId++;

        emit IdGenerated(msg.sender, newId);
        return newId;
    }

    function getId(address _addr) public view returns (uint256) {
        if (_addr == address(0)) revert InvalidAddress();
        if (addressToId[_addr] == 0) revert NoIdGenerated();
        return addressToId[_addr];
    }

    function getAddr(uint256 _id) public view returns (address) {
        if (_id <= 0 || _id >= nextId) revert InvalidId();
        address addr = idToAddress[_id];
        if (addr == address(0)) revert NoAddressFound();
        return addr;
    }

    function resetIdForAddress(address _addr) external onlyOwner {
        uint256 id = addressToId[_addr];
        if (id == 0) revert NoIdGenerated();

        delete addressToId[_addr];
        delete idToAddress[id];
    }
}
