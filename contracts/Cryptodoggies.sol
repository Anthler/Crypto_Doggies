pragma solidity >=0.4.24 < 0.6.0;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import '../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol';


contract AccessControl {
    /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles
    address payable ceoAddress;
    address payable cooAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev The AccessControl constructor sets the original C roles of the contract to the sender account
    constructor() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for any CLevel functionality
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO
    /// @param _newCEO The address of the new CEO
    function setCEO(address payable _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO
    /// @param _newCOO The address of the new COO
    function setCOO(address payable _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Pause the smart contract. Only can be called by the CEO
    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Only can be called by the CEO
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

contract CryptoDoggies is ERC721, AccessControl, Ownable{
    using SafeMath for uint;

    event TokenCreated(uint tokenId, string name, bytes5 dna, uint price ,address owner);
    event TokenSold(uint indexed tokenId, string name, bytes5 dna, uint sellingPrice, uint newPrice, address indexed oldOwner, address indexed newOwner  );
    
    mapping(uint => address payable) private tokenIdToOwner;
    mapping(uint => uint) private tokenIdToPrice;
    mapping(address => uint) private ownershipTokenCount;
    mapping(uint => address) private tokenIdToApproved;

    struct Doggy{
        string name;
        bytes5 dna;
    }

    Doggy[] private doggies;

    uint private startingPrice = 0.01 ether;
    bool private erc721Enabled = false;

    modifier onlyERC721(){
        require(erc721Enabled, 'ERC721 not enabled');
        _;
    }

    function createToken(string memory _name, address _owner, uint _price) public {
            require(_owner != address(0), 'empty address specified');
            require(_price >= startingPrice ,'Price is invalid');
            bytes5 _dna = _generateRandomDna();
            _createToken(_name, _dna, _owner, _price);
    }
    //requires access control modifier
    function createToken(string memory _name) public{
        bytes5 _dna = _generateRandomDna();
        _createToken(_name, _dna, address(this), startingPrice);
    }

    function _createToken(string memory _name, bytes5 _dna, address _owner, uint _price) private{
        
        Doggy memory _doggy = Doggy({
            name: _name,
            dna:_dna
        });
        uint _newTokenId = doggies.push(_doggy)-1;
        tokenIdToPrice[_newTokenId] = _price;
        emit TokenCreated(_newTokenId, _name, _dna, _price, _owner);
        _transfer(address(0), _owner, _newTokenId);
    }

    function _generateRandomDna() private view returns (bytes5 _dna) {
        uint256 lastBlockNumber = block.number - 1;
        bytes32 hashVal = bytes32(blockhash(lastBlockNumber));
         assembly {
            _dna := mload(add(hashVal, 0x05))
        }
        
        //bytes5 dna = bytes5((hashVal & bytes32(0xffffffff)) << 216);
        //return dna;
    }

    function getToken(uint _tokenId) public returns(string memory _tokenName, bytes5 _dna, uint _price, uint _nextPrice, address _owner){
        _tokenName = doggies[_tokenId].name;
        _dna = doggies[_tokenId].dna;
        _price = tokenIdToPrice[_tokenId];
        _nextPrice = nextPriceOf(_tokenId);
        _owner = tokenIdToOwner[_tokenId];
    }

    function getAllTokens() private returns(uint[] memory, uint[] memory, address[] memory){
        uint total = totalSupply();
        uint[] memory prices = new uint[](total);
        uint[] memory nextPrices = new uint[](total);
        address[] memory owners = new address[](total);

        for (uint i = 0; i < total; i++) {
            prices[i] = tokenIdToPrice[i];
            nextPrices[i] = nextPriceOf(i);
            owners[i] = tokenIdToOwner[i];
        }

        return(prices, nextPrices, owners);
     }

     function getTokensOf(address _owner) public returns(uint[] memory){
         uint tokenCount = balanceOf(_owner);
         if(tokenCount == 0){
             return new uint[](0);
         }else{
             uint[] memory result = new uint[](tokenCount);
             uint total = totalSupply();
             uint resultIndex = 0;

             for(uint i = 0; i< total; i++){
                 if(tokenIdToOwner[i] == _owner){
                     result[resultIndex] = i;
                     resultIndex++;
                 }
             }

            return result; 
         }
     }

    function withdrawBalance(uint _amount, address payable _to) public onlyCEO{
         require(_amount <= address(this).balance);
         if(_amount == 0){
             _amount = address(this).balance;
         }

         if(_to == address(0)){
             ceoAddress.transfer(_amount);
         }else{
             _to.transfer(_amount);
         }
     }

    function purchase(uint _tokenId) public payable whenNotPaused{
        
       // address oldOwner = ;
        address payable oldOwner = address(uint160(ownerOf(_tokenId)));
        address payable newOwner = msg.sender;
        uint sellingPrice = priceOf(_tokenId);
        require(oldOwner == address(0));
        require(newOwner == address(0));
        require(oldOwner != newOwner);
        require(! _isContract(newOwner));
        require(sellingPrice > 0);
        require(msg.value >= sellingPrice);
        _transfer(oldOwner, newOwner, _tokenId);

        emit TokenSold(_tokenId, doggies[_tokenId].name,doggies[_tokenId].dna,sellingPrice, priceOf(_tokenId), oldOwner, newOwner);
        uint excess = msg.value.sub(sellingPrice);
        uint contractCut = msg.value.mul(6).div(100);
        if(oldOwner != address(this)){
            oldOwner.transfer(sellingPrice.sub(contractCut));
        }

        if(excess > 0){
            newOwner.transfer(excess);
        }
    }

    function priceOf(uint _tokenId) public returns(uint){
        return  tokenIdToPrice[_tokenId];
    }

    uint private increaseLimit1 = 0.2 ether;
    uint private increaseLimit2 = 0.5 ether;
    uint private increaseLimit3 = 2.0 ether;
    uint private increaseLimit4 = 5.0 ether;
    function nextPriceOf(uint _tokenId) public returns(uint){
        uint _price = priceOf(_tokenId);
        if(_price < increaseLimit1){
            return _price.mul(200).div(95);
        }else if(_price < increaseLimit2){
             return _price.mul(135).div(96); 
        }else if(_price < increaseLimit3){
             return _price.mul(125).div(97); 
        }else if(_price < increaseLimit4){
             return _price.mul(117).div(97); 
        }else{
             return _price.mul(115).div(98); 
        }
    }

    function enableERC721() public onlyCEO{
        erc721Enabled = true;
    }

    function totalSupply()public returns(uint _totalSupply){
        _totalSupply = doggies.length;
    }

    function balanceOf(address _owner) public view returns(uint _balance){
        _balance = ownershipTokenCount[_owner];
    }

    function ownerOf(uint _tokenId) public view returns(address _owner){
       return _owner = address(tokenIdToOwner[_tokenId]);
    }

    function approve(address _to, uint _tokenId) public whenNotPaused onlyERC721{
        require(_owns(msg.sender, _tokenId));
        tokenIdToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from,address _to, uint _tokenId) public whenNotPaused onlyERC721{
        require(_to != address(0));
        require(_owns(_from, _tokenId));

        _transfer(_from,_to, _tokenId);
    }

    function transfer(address _from , address _to, uint _tokenId) public{
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender,_to, _tokenId);
    }

    function implementsERC721() public view whenNotPaused returns(bool){
        return erc721Enabled;
    }
    
    function takeOwnership(uint _tokenId) public whenNotPaused onlyERC721 {
        require(_approved(msg.sender, _tokenId));
        _transfer(tokenIdToOwner[_tokenId],msg.sender, _tokenId);
    }
    
    function name() public view returns(string memory _name){
        return _name = "CryptoDoggies";
    }
    
    function symbol() public view returns(string memory _symbol){
        return _symbol = "CDT";
    }
    
    function _owns(address _claimant, uint _tokenId) private view returns(bool){
        return tokenIdToOwner[_tokenId] == _claimant;
    }
    
    function _approved(address _to, uint _tokenId) private view returns(bool){
        return tokenIdToApproved[_tokenId] == _to;
    }
    
    function _transfer(address _from, address _to, uint _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIdToOwner[_tokenId] == _to;
        if(_from != address(0)){
            ownershipTokenCount[_to]--;
            delete tokenIdToApproved[_tokenId];
        }
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function _isContract(address account) private view returns(bool){
        uint size;
        assembly{size := extcodesize(account)}
        return size > 0;
    }

}




