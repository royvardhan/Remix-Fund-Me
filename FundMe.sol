// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

// eth:usd 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e ChainLink Datafeed Rinkeby

error NotOwner() // alternative to *require - check modifier onlyOnwer

contract FundMe {

    address public owner;

    // address public immutable i_owner; // same functionality as the above line but saves on gas

    constructor () {
       owner = msg.sender;
    }

    modifier onlyOwner {
        // require(msg.sender == owner, "Only the owner can do this"); // this is better but not gas efficient
        if (msg.sender != owner) {revert NotOnwer();} // // alternative to *require - check error NotOwner() - saves gas
        _;
    }

    uint256 public minUsd = 50 * 1e18;
    // uint256 public constant minUsd = 50 * 1e18; // Added constant to decrease gas fees at the time of deployment OR viewing the variable.
    address[] public funders;
    mapping (address => uint256) public addressToAmountFunded;
    
    function fund() public payable {
        require(getConversionRate(msg.value) >= minUsd, "Not enough ether");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // resetting the funders array to zero length
        payable(msg.sender).transfer(address(this).balance); // withdrawing using the TRANSFER method

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);  // withdrawing using the SEND method
        // require(sendSuccess, "Failed to send funds");                        // withdrawing using the SEND method

        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("") // withdrawing using the CALL method
        // require(callSuccess, "Call failed");       // This is the recommended way                                  // withdrawing using the CALL method

    }
}