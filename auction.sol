// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Auction {
    address payable public auctioneer;

    uint256 public startTimeBlock;
    uint256 public endTimeBlock;

    enum auc_state {
        Started,
        Running,
        End,
        Cancelled
    }

    auc_state public auctionState;

    uint256 public highestPayableBid;
    uint256 public bidInc;

    address payable public highestBidder;

    mapping(address => uint256) public bids;

    constructor() {
        auctioneer = payable(msg.sender);
        auctionState = auc_state.Running;
        startTimeBlock = block.number;
        endTimeBlock = startTimeBlock + 240;
        bidInc = 1 ether;
    }

    modifier notOwner() {
        require(msg.sender != auctioneer, "Auctioneer cannot access or Bid");
        _;
    }

    modifier Owner() {
        require(msg.sender == auctioneer, "Only auctioneer can access");
        _;
    }

    modifier started() {
        require(block.number > startTimeBlock, "Bid has not started yet");
        _;
    }

    modifier beforeEnd() {
        require(block.number < endTimeBlock, "Bid is over you cannot Bid now");
        _;
    }

    function endAuction() public Owner {
        auctionState = auc_state.End;
    }

    function cancelAuc() public Owner {
        require(
            auctionState == auc_state.Running,
            "Auction is not started yet"
        );
        auctionState = auc_state.Cancelled;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a <= b) return a;
        else return b;
    }

    function Bid() public payable notOwner started beforeEnd {
        require(auctionState == auc_state.Running);
        require(msg.value >= 1 ether, "Minimum Bid is of  1 ether");

        uint256 currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestPayableBid);
        bids[msg.sender] = currentBid;

        if (currentBid < bids[highestBidder]) {  
            highestPayableBid = min(currentBid + bidInc, bids[highestBidder]);
        } else {
            highestPayableBid = min(currentBid, bids[highestBidder] + bidInc);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public {
        require(
            auctionState == auc_state.Cancelled ||
                auctionState == auc_state.End ||
                block.number > endTimeBlock
        );

        require(msg.sender == auctioneer || bids[msg.sender] > 0);

        address payable person;
        uint256 value;

        if (auctionState == auc_state.Cancelled) {
            person = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == auctioneer) {
                person = auctioneer;
                value = highestPayableBid;
            } else {
                if (msg.sender == highestBidder) {
                    person = highestBidder;
                    value = highestPayableBid - bids[highestBidder];
                } else {
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(value);
    }
}
