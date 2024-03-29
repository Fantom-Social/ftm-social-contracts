// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Strings.sol"; //This just converts a uint to a string. It's just used for the placeholder username in line <FILL HERE>

interface IERC20 {
    //all basic erc-20 functions
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender)external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}
contract FantomSocial is IERC20 {
    string public constant name = "FSM Dao Token";
    string public constant symbol = "FSMD";
    uint8 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_ = 0 ether;
    constructor() {
        balances[msg.sender] += 3650000 ether;
        totalSupply_ += 3650000 ether;
        emit Transfer(address(0), msg.sender, 3650000 ether);
        lastCall = block.timestamp / 86400;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address tokenOwner) public view override returns (uint256) {
        return balances[tokenOwner];
    }
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        if (receiver == address(0x0)) {
            
        }
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view override returns (uint256) {
        return allowed[owner][delegate];
    }
    function transferFrom(address owner,address buyer,uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    address[] public addresses;

    mapping(address => Profile) public profiles;
    Profile[] public profiles_;
    function getProfiles() public view returns(Profile[] memory) {
        return(profiles_);
    }
    Post[] public posts;
    struct Profile {
        address owner;
        string name;
        uint256 timeCreated;
        uint256 id;
    }
    struct Post {
        uint256 author;
        string content;
        uint256 blockCreated;
        uint256 id;
        uint256 harmful; // (0, 1, 2, 3) = (No Proposal, Proposal Ongoing, Post Safe, Post Unsafe)
        bool isComment;
        uint256 timeCreated;
    }

    mapping(uint256 => uint256) public commentOf;
    mapping(uint256 => uint256[]) public comments;

    mapping(address => Lock) public locks;
    struct Lock {
        uint256 end;
        uint256 value;
    }
        function lock() public payable {
        require(msg.value == 1 ether);
        require(locks[msg.sender].value == 0);
        locks[msg.sender].end = block.timestamp + 14 days;
        locks[msg.sender].value = 1 ether;
            if (profiles[msg.sender].owner != msg.sender) {
            totalAmountLocked[msg.sender] = 0;
            profiles[msg.sender] = Profile({owner: msg.sender, name: string.concat("New User ", Strings.toString(addresses.length)),timeCreated: block.number,id: addresses.length});
            profiles_.push(profiles[msg.sender]);
            addresses.push(msg.sender);
    }
        }
    
 function unlock() public lockedValue() {
        require(locks[msg.sender].end < block.timestamp);
        locks[msg.sender].value = 0;
        payable(msg.sender).transfer(1 ether);
    }
    modifier lockedValue() {
        require(locks[msg.sender].value == 1 ether);
        _;
    }
    modifier profileExists(address _address) {
        require(profiles[_address].owner != address(0x0));
        _;
    }
    modifier nonEmptyInput(string calldata _input) {
        require(keccak256(abi.encodePacked(_input)) !=keccak256(abi.encodePacked("")));
        _;
    }
    function changeNickname(string calldata _name) public lockedValue() nonEmptyInput(_name) { 
        require(bytes(_name).length <= 66);
        profiles[msg.sender].name = _name;
    }
    function createPost(string calldata _content, bool isComment_, uint256 commentOf_) external lockedValue() nonEmptyInput(_content) {
        Post memory newPost = Post({author: profiles[msg.sender].id,content: _content, blockCreated: block.number,id: posts.length,harmful: 0, isComment: isComment_, timeCreated: block.timestamp});
        if (isComment_ == true) {
            require(posts[commentOf_].timeCreated != 0);
            commentOf[posts.length] = commentOf_;
            comments[commentOf_].push(posts.length);
        }
        posts.push(newPost);
    }
    function getPosts() external view returns (Post[] memory) {
        return posts;
    }
    function getAddresses() external view returns (address[] memory) {
        return addresses;
    }
    //DAO
    mapping(address => uint256) totalAmountLocked; //For security
    uint256 public lastCall;
    struct Proposal {
        address reporter;
        uint256 id;
        uint256 deadline;
        string desc;
        bool finished;
        uint256 postId;
    }
    mapping(uint256 => mapping(address => bool)) public votedYes;
    mapping(uint256 => address[]) public voters;
    mapping(uint256 => address[]) public payoutReceivers;
    mapping(uint256 => mapping(bool => address[])) public payouts;
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) voted;
    function newProposal(string memory _desc, uint256 postId) lockedValue() public payable returns (Proposal memory) {
        require(posts[postId].id != 0);
        require(msg.value == 1000000000000000000);
        require(posts[postId].harmful == 0 /*undecided post status*/);
        totalAmountLocked[msg.sender] += 1 ether; //Add 1 ftm locked
        voters[proposals.length].push(msg.sender);
        votedYes[proposals.length][msg.sender] = true;
        voted[proposals.length][msg.sender] = true;
        proposals.push(Proposal(msg.sender,proposals.length,(block.timestamp + 24 hours),_desc,false,postId));
        posts[postId].harmful = 1; //status being decided
        return (proposals[proposals.length - 1]);
    }
    function vote(bool support, uint256 id) lockedValue() public payable {
        require(proposals[id].reporter != address(0x0));
        require(msg.value == 1000000000000000000); //has value to lock
        require(voted[id][msg.sender] != true); //not voted yet
        require(proposals[id].finished == false); //proposal is not ended
        voted[id][msg.sender] = true;

        if (proposals[id].deadline <= block.timestamp) {
            proposals[id].finished = true;
            //Last vote
            totalAmountLocked[msg.sender] += 1 ether; //Add 1 ftm locked
        voters[id].push(msg.sender);
        votedYes[id][msg.sender] = support;
            //Extra
            uint yesTokens = 0;
            uint noTokens = 0;
            uint yesVotes = 0;
            uint noVotes = 0;
            for (uint256 i = 0; i < voters[id].length; i++) {

                if (votedYes[id][voters[id][i]] == true) {
                    payouts[id][true].push(voters[id][i]);
                    yesVotes++;
                    yesTokens += balances[voters[id][i]];
                    //UNLOCKED ETHER
                    require(totalAmountLocked[voters[id][i]] >= 1 ether);
                    totalAmountLocked[voters[id][i]] -= 1 ether;
                    payable(voters[id][i]).transfer(1 ether);
                } else {
                    payouts[id][false].push(voters[id][i]);
                    noVotes++;
                    noTokens += balances[voters[id][i]];
                    //UNLOCKED ETHER
                    require(totalAmountLocked[voters[id][i]] >= 1 ether);
                    totalAmountLocked[voters[id][i]] -= 1 ether;
                    payable(voters[id][i]).transfer(1 ether);
                }
            }
            uint yesPercent = (yesTokens/(noTokens + yesTokens))/2 + (yesVotes/(yesVotes+noVotes))/2;
            uint noPercent = (noTokens/(noTokens + yesTokens))/2 + (noVotes/(yesVotes+noVotes))/2;
            if (yesPercent >= noPercent) {
                posts[proposals[id].postId].harmful = 3; //bad post
                for (uint a = 0; a < payouts[id][true].length; a++) {
                    payoutReceivers[block.timestamp/86400].push(payouts[id][true][a]);
                }
            } else  {
                posts[proposals[id].postId].harmful = 2; //good post
                for (uint a = 0; a < payouts[id][false].length; a++) {
                    payoutReceivers[block.timestamp/86400].push(payouts[id][true][a]);
                }
            }
        } else {
            //Normal vote
        totalAmountLocked[msg.sender] += 1 ether; //Add 1 ftm locked
        voters[id].push(msg.sender);
        votedYes[id][msg.sender] = support;
        }
    }
    function distribute() external {
        require(lastCall < block.timestamp/86400);
        for (uint i = lastCall; i < block.timestamp/86400; i++) {
            totalSupply_ += 100 ether;
            if (payoutReceivers[i].length == 0) {
                balances[address(0x0)] += 100 ether;
                emit Transfer(address(0x0), address(0x0), 100 ether);
            } else {
                for (uint256 a = 0; a < payoutReceivers[i].length; a++) {
                    balances[payoutReceivers[i][a]] += 100 ether/payoutReceivers[i].length;
                    emit Transfer(address(0x0), payoutReceivers[i][a], 100 ether/payoutReceivers[i].length);
                }
                balances[address(0x0)] += 100 ether - (100 ether/payoutReceivers[i].length)*payoutReceivers[i].length;
                emit Transfer(address(0x0), address(0x0), 100 ether - (100 ether/payoutReceivers[i].length)*payoutReceivers[i].length);
            }
        }
        lastCall = (block.timestamp/86400);
    }

    function getProposals() public view returns (Proposal[] memory) {
        return(proposals);
    }
}
