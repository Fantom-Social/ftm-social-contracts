// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

//This document is currently untested and awaiting a testnet phase. Please do not use it in production.

interface FantomSocial {
    function locks(address) external view returns (uint256 end, uint256 value);
    function profiles(address) external view returns (address owner, string memory name, uint256 timeCreated, uint256 id);
    function posts(uint256) external view returns (address author, string memory content, uint256 timeCreated, uint256 id, uint256 harmful);

}

contract AddOns {
    address public addr;
    struct Index {
        bool isListed;
        uint256 index;
    }

    mapping(address => address[]) public followers;
    mapping(address => address[]) public following;
    mapping(address => mapping(address => Index))  internal followersIndex;
    mapping(address => mapping(address => Index)) internal followingIndex;

    function getFollowers(address addr_) public view returns(address[] memory) {
        return(followers[addr_]);
    }
    function getFollowing(address addr_) public view returns(address[] memory) {
        return(following[addr_]);
    }


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
        require(followingIndex[msg.sender][_address].isListed != true);
        followersIndex[_address][msg.sender] = Index(true,followers[_address].length);
        followingIndex[msg.sender][_address] = Index(true, following[msg.sender].length);
        followers[_address].push(msg.sender);
        following[msg.sender].push(_address);
    }

    function unfollow(address _address) external profileExists(_address) lockedValue {
        require(followingIndex[msg.sender][_address].isListed == true);
        followersIndex[_address][msg.sender].isListed = false;
        followingIndex[msg.sender][_address].isListed = false;
        delete followers[_address][followingIndex[_address][msg.sender].index];
        delete following[msg.sender][followingIndex[msg.sender][_address].index];
    }

    mapping(uint256 => address[]) public likes;
    mapping(uint256 => mapping(address => Index)) internal likesIndex;

    function getLikes(uint256 postId_) public view returns(address[] memory) {
        return(likes[postId_]);
    }

    //Add post exists modifier to governance reporting too (if not added)
    modifier postExists(uint256 postId) {
        (address author, string memory content, uint256 timeCreated, uint256 id, uint256 harmful) = FantomSocial(addr).posts(postId);
        require(author != address(0x0));
        _;
    }

    function like(uint256 postId) postExists(postId) public {
        require(likesIndex[postId][msg.sender].isListed == false);
        likesIndex[postId][msg.sender] = Index(true, likes[postId].length);
        likes[postId].push(msg.sender);
    }
    function unlike(uint256 postId) postExists(postId) public {
        require(likesIndex[postId][msg.sender].isListed == true);
        likesIndex[postId][msg.sender].isListed == false;
        delete likes[postId][likesIndex[postId][msg.sender].index];
    }
}
