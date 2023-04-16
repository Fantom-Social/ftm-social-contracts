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

    mapping(address => address[]) public followers;
    mapping(address => address[]) public following;
    mapping(address => mapping(address => uint256))  internal followersIndexMap;
    mapping(address => mapping(address => uint256)) internal followingIndexMap;

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
        require(followersIndexMap[_address][msg.sender] == 0, "Already following");
        require(followers[_address][0] != msg.sender);
        followersIndexMap[_address][msg.sender] = followers[_address].length;
        followingIndexMap[msg.sender][_address] = following[msg.sender].length;
        followers[_address].push(msg.sender);
        following[msg.sender].push(_address);
    }

    function unfollow(address _address) external profileExists(_address) lockedValue {
        require(followersIndexMap[_address][msg.sender] != 0, "Already not following");

        require(followers[_address][0] != msg.sender);
        address[] storage f = following[msg.sender];
        address[] storage f_ = followers[_address];
        uint256 followingIndexToDelete = followingIndexMap[msg.sender][_address];
        uint256 followersIndexToDelete = followersIndexMap[_address][msg.sender];

        require(followingIndexToDelete < f.length, "Object not found");
        require(followersIndexToDelete < f.length, "Object not found");

        if (followingIndexToDelete != f.length - 1) {
            address lastObj = f[f.length - 1]; //Gets value of last element of array
            f[followingIndexToDelete] = lastObj;
            followingIndexMap[msg.sender][lastObj] = followingIndexToDelete;
        }
        if (followersIndexToDelete != f_.length - 1) {
            address lastObj = f_[f_.length - 1]; //Gets value of last element of array
            f_[followersIndexToDelete] = lastObj; 
            followersIndexMap[_address][lastObj] = followersIndexToDelete; 
        }

        f.pop();
        f_.pop();
        delete followersIndexMap[_address][msg.sender];
        delete followingIndexMap[msg.sender][_address];
    }

    mapping(uint256 => address[]) public likes;
    mapping(uint256 => mapping(address => uint256)) internal likesIndexMap;

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
        require(likesIndexMap[postId][msg.sender] == 0); //TODO
        require(likes[postId][0] != msg.sender);
        likesIndexMap[postId][msg.sender] = likes[postId].length;
        likes[postId].push(msg.sender);
    }

    function unlike(uint256 postId) postExists(postId) public {
        require(likesIndexMap[postId][msg.sender] != 0); //TODO

        address[] storage l = likes[postId];
        uint256 likesIndexToDelete = likesIndexMap[postId][msg.sender];

        require(likesIndexToDelete < l.length, "Object not found");

        if (likesIndexToDelete != l.length - 1) {
            address lastObj = l[l.length - 1]; //Gets value of last element of array
            l[likesIndexToDelete] = lastObj;
            likesIndexMap[postId][lastObj] = likesIndexToDelete;
        }
        
        l.pop();
        delete likesIndexMap[postId][msg.sender];
    }
}
