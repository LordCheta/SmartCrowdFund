// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SmartCrowdFund {

    mapping(address => uint) public contributors;
    address public admin; 
    uint public noOfContributors;
    uint public minContribution;
    uint public deadline; // timestamp (seconds)
    uint public fundGoal;
    uint public raisedAmount; 

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping (address => bool) voters;
    }

    mapping(uint => Request) public requests;

    uint public numRequests;

    constructor(uint _fundGoal, uint _deadline) {
        fundGoal = _fundGoal;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
        admin = msg.sender;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    function contribute() public payable {
        require(block.timestamp < deadline, "The deadline for this fund has passed");
        require(msg.value >= minContribution, "Minimum contirbution for this fund is not met");
         
         // We want to increment the number of contributors only once for each contributor
         // so this checks to make sure a contributor hasn't previously made a contribution
         // before proceeding to increment the noOfContributors. 
         if(contributors[msg.sender] == 0) {
            noOfContributors++;
         }

         contributors[msg.sender] += msg.value;
         raisedAmount += msg.value;

         emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable external {
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < fundGoal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];

        recipient.transfer(value);

        contributors[msg.sender] = 0;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be a contributor to vote");

        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "You have already voted");

        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin {
        require(raisedAmount >= fundGoal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "This request has alreaady been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2); // 50% voted for theis request

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}