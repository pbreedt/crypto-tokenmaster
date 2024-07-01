// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TokenMaster is ERC721 {
    address public owner;
    uint256 public totalOccasions;
    uint256 public totalSupply; // total number of tickets

    mapping(uint256 => Occasion) occasions;
    mapping(uint256 => mapping(uint256 => address)) public seatAssignment; // sample calls this seatTaken
    mapping(uint256 => mapping(address => bool)) public hasBought;
    mapping(uint256 => uint256[]) public seatsTaken;

    struct Occasion {
        uint256 id;
        string name;
        uint256 cost;
        uint256 ticketsAvailable;  // sample use name 'tickets', but same type seems like no problems created in abi
        uint256 maxTickets;
        string date;
        string time;
        string location;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol) {
        owner = msg.sender;
    }

    function list(
        string memory _name,
        uint256 _cost,
        uint256 _maxTickets,
        string memory _date,
        string memory _time,
        string memory _location
    ) external onlyOwner {
        totalOccasions++;
        
        occasions[totalOccasions] = Occasion(
            totalOccasions,
            _name,
            _cost,
            _maxTickets,
            _maxTickets,
            _date,
            _time,
            _location
        );
    }

    function mint(uint256 _occasionId, uint256 _seatId) external payable {
        require(_occasionId > 0, "Occasion ID must be greater than 0");
        require(_occasionId <= totalOccasions, "Occasion ID must be less than total occasions");
        require(msg.value >= occasions[_occasionId].cost, "Insufficient funds");
        require(occasions[_occasionId].ticketsAvailable > 0, "No tickets left");
        // Require that the seat is not taken, and the seat exists...
        require(seatAssignment[_occasionId][_seatId] == address(0), "Seat already taken");
        require(_seatId <= occasions[_occasionId].maxTickets, "Seat ID must be less than max tickets");

        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        occasions[_occasionId].ticketsAvailable--;
        seatAssignment[_occasionId][_seatId] = msg.sender;
        // example uses 'seatsTaken array' to keep track of assigned seats, I will attempt to use seatAssignment
        seatsTaken[_occasionId].push(_seatId);
        hasBought[_occasionId][msg.sender] = true;  // possibly also use seatAssignment for this?
    }

    // this is a bit tricky without 'mapping(uint256 => uint256[]) seatsTaken'
    // may require some looping and a temp array
    function getSeatsTaken(uint256 _id) public view returns (uint256[] memory) {
        return seatsTaken[_id];
    }

    function getOccasion(uint256 _id)
    public view
    returns (Occasion memory) {
        return occasions[_id];
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

}
