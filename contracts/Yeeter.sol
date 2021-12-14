// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./MolochFlat.sol";
import "./Wrapper.sol";

contract Yeeter {
    event Received(address, uint256);
    mapping(address => uint256) public deposits;
    uint256 maxTarget;
    uint256 raiseEndTime;
    uint256 raiseStartTime;
    uint256 maxUnitsPerAddr; 
    uint256 pricePerUnit;
    uint256 lootPerUnit;

    uint256 balance;
    Moloch public moloch;
    Wrapper public wrapper;

    function init(
        address _moloch,
        address payable _wrapper,
        uint256 _maxTarget, // max raise target
        uint256 _raiseEndTime,
        uint256 _raiseStartTime,
        uint256 _maxUnits, // per individual
        uint256 _pricePerUnit,
        uint256 _lootPerUnit
    ) public {
        require(address(moloch) == address(0), "already init");
        moloch = Moloch(_moloch);
        wrapper = Wrapper(_wrapper);

        maxTarget = _maxTarget;
        raiseEndTime = _raiseEndTime;
        raiseStartTime = _raiseStartTime;
        maxUnitsPerAddr = _maxUnits;
        pricePerUnit = _pricePerUnit;
        lootPerUnit = _lootPerUnit;

    }

    // set sumoners (share holders)
    receive() external payable {
        require(address(moloch) != address(0), "!init");
        require(msg.value > pricePerUnit, "< minimum");
        require(balance < maxTarget, "Max Target reached"); // balance plus newvalue
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
        (bool success, ) = address(wrapper).call{value: newValue}("");
        require(success, "wrap failed");
        // send to dao
        require(
            wrapper.transfer(address(moloch), newValue),
            "transfer failed"
        );

        if (msg.value > newValue) {
            // Return the extra money to the minter.
            (bool success2, ) = msg.sender.call{value: msg.value - newValue}("");
            require(success2, "Transfer failed");
        }

        // can probably get rid of this extra logic
        // if (deposits[msg.sender] > 0) {
        deposits[msg.sender] = deposits[msg.sender] + newValue;
        // } else {
        //     deposits[msg.sender] = newValue;
        // }

        balance = balance + newValue;

        uint256[] memory _summonerShares = new uint256[](1);
         _summonerShares[0] = uint256(numUnits * lootPerUnit);
        uint256[] memory _summonerLoot = new uint256[](1);
        _summonerLoot[0] = uint256(0);
        address[] memory _msgSender = new address[](1);
        _msgSender[0] = msg.sender;

        moloch.setSharesLoot(_msgSender, _summonerShares, _summonerLoot, true);

        moloch.collectTokens(address(wrapper));

        emit Received(msg.sender, newValue);
    }

    function goalReached() public view returns (bool) {
        return balance >= maxTarget;
    }
}


contract CloneFactory1 {
    // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

contract YeetSummoner is CloneFactory1 {
    address payable public template;
    mapping(uint256 => address) public yeeters;
    uint256 public yeetIdx = 0;

    // Moloch private moloch; // moloch contract

    constructor(address payable _template) {
        template = _template;
    }

    event SummonYeetComplete(
        address indexed moloch,
        address wrapper,
        uint256 maxTarget,
        uint256 raiseEndTime,
        uint256 raiseStartTime,
        uint256 maxUnits,
        uint256 pricePerUnit,
        uint256 lootPerUnit
    );


    function summonYeet(
        address _moloch,
        address payable _wrapper,
        uint256 _maxTarget,
        uint256 _raiseEndTime,
        uint256 _raiseStartTime,
        uint256 _maxUnits,
        uint256 _pricePerUnit,
        uint256 _lootPerUnit
    ) public returns (address) {
        Yeeter yeeter = Yeeter(payable(createClone(template)));

        yeeter.init(
        _moloch,
        _wrapper,
        _maxTarget,
        _raiseEndTime,
        _raiseStartTime,
        _maxUnits,
        _pricePerUnit,
        _lootPerUnit
        );
        yeetIdx = yeetIdx + 1;
        yeeters[yeetIdx] = address(yeeter);
        emit SummonYeetComplete(
        _moloch,
        _wrapper,
        _maxTarget,
        _raiseEndTime,
        _raiseStartTime,
        _maxUnits,
        _pricePerUnit,
        _lootPerUnit
        );

        return address(yeeter);
    }

}