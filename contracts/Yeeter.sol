pragma solidity ^0.6.1;

import "./MolochFlat.sol";
import "./Wrapper.sol";

/**
    "tributeToken":"0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d",
    "tributeTokenSymbol":"wxDAI",
    "claimTokenAddress":"0x97Edc0e345FbBBd8460847Fcfa3bc2a13bF8641F",
    "claimTokenSymbol":"RICE",
    "ratio":"1.42",
    "raiseStartTime":"1622898000",
    "raiseEndTime":"1622984400",
    "claimPeriodStartTime":"1623070800",
    "minTarget":"100",
    "maxTarget":"34500",
    "maxContribution":"500",
    "minContribution":"100",
     */
contract Yeeter {
    event Received(address, uint256);
    mapping(address => uint256) public deposits;
    uint256 maxTarget;
    uint256 raiseEndTime;
    uint256 raiseStartTime;
    uint256 maxUnitsPerAddr; // do we need to worry about this (maybe do incrmental, like nft set price, so many units)
    uint256 pricePerUnit;
    uint256 lootPerUnit;

    uint256 balance;
    Moloch public moloch;
    Wrapper public wrapper;

    function init(
        address _moloch,
        address payable _wrapper,
        uint256 _maxTarget,
        uint256 _raiseEndTime,
        uint256 _raiseStartTime,
        uint256 _maxUnits,
        uint256 _pricePerUnit,
        uint256 _lootPerUnit
    ) public {
        require(address(moloch) == address(0), "already set");
        moloch = Moloch(_moloch);
        wrapper = Wrapper(_wrapper);

        maxTarget = _maxTarget;
        raiseEndTime = _raiseEndTime;
        raiseStartTime = _raiseStartTime;
        maxUnitsPerAddr = _maxUnits;
        pricePerUnit = _pricePerUnit;
        lootPerUnit = _lootPerUnit;

    }

    receive() external payable {
        require(msg.value > pricePerUnit, "< minimum");
        require(balance < maxTarget, "Max Target reached");
        require(block.timestamp < raiseEndTime, "Time is up");
        require(block.timestamp > raiseStartTime, "Not Started");
        uint256 numUnits = msg.value / pricePerUnit; // floor units
        uint256 newValue = numUnits * pricePerUnit;
        // if some one yeets over max should we give them the max and return leftover.
        require(
            deposits[msg.sender] + newValue <= maxUnitsPerAddr * pricePerUnit,
            "can not deposit more than max"
        );

        // wrap
        (bool success, ) = address(wrapper).call.value(newValue)("");
        require(success, "wrap failed.");
        // send to dao
        require(
            wrapper.transfer(address(moloch), newValue),
            "WrapNZap: transfer failed"
        );

        if (msg.value > newValue) {
            // Return the extra money to the minter.
            (bool success2, ) = msg.sender.call.value(msg.value - newValue)("");
            require(success2, "Transfer failed.");
        }

        if (deposits[msg.sender] > 0) {
            deposits[msg.sender] = deposits[msg.sender] + newValue;
        } else {
            deposits[msg.sender] = newValue;
        }

        balance = balance + newValue;
        moloch.setSharesLoot(msg.sender, 0, numUnits * lootPerUnit, true);

        emit Received(msg.sender, msg.value);
    }

    // function goalReached() public view return (bool) {
    //     return balance == maxCap;
    // }
}
