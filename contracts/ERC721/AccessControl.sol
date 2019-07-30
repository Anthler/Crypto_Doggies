pragma solidity >=0.4.24 < 0.5.0;

contract AccessControl {

    address public ceoAddress;
    address public cooAddress;
    bool public paused = false;
    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}



