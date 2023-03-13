// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
//WARNING: THIS DOCUMENT IS UNTESTED
interface FantomSocial {
    function locks(address) external view returns (uint256 end, uint256 value);
    function profiles(address) external view returns (address owner, string memory name, uint256 timeCreated, uint256 id);
}

contract AddOns {
    address public addr;
    struct followIndex {
        bool isListed;
        uint256 index;
    }
    mapping(address => address[]) public followers;
    mapping(address => address[]) public following;
    mapping(address => mapping(address => followIndex)) followersIndex;
    mapping(address => mapping(address => followIndex)) followingIndex;

    constructor(address addr_) {
        addr = addr_;
    }

    modifier profileExists(address _address) {
        (address owner, string memory name, uint256 timeCreated, uint256 id) = FantomSocial(addr).profiles(_address);
        require(owner != address(0x0));
        _;
    }

    modifier lockedValue() {
        (uint256 end, uint256 value) = FantomSocial(addr).locks(msg.sender);
        require(value == 1 ether);
        _;
    }

    function follow(address _address) external profileExists(_address) lockedValue {
        require(msg.sender != _address);
        require(followingIndex[msg.sender][_address].isListed != true); //no double follow
        followersIndex[_address][msg.sender] = followIndex(true,followers[_address].length);
        followers[_address].push(msg.sender);
        followingIndex[msg.sender][_address] = followIndex(true, following[msg.sender].length);
        following[msg.sender].push(_address);
    }

    function unfollow(address _address) external profileExists(_address) lockedValue {
        require(msg.sender != _address);
        require(followingIndex[msg.sender][_address].isListed == true);
        delete followers[_address][followingIndex[_address][msg.sender].index];
        followersIndex[_address][msg.sender].isListed = false;
        delete following[msg.sender][followingIndex[msg.sender][_address].index];
        followingIndex[msg.sender][_address].isListed = false;
    }
}
