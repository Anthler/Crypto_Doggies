pragma solidity >=0.4.24 < 0.5.0;

contract ERC721 {
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function totalSupply() public view returns (uint256 _totalSupply);

    function balanceOf(address _owner) public view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    function approve(address _to, uint256 _tokenId) public;

    // NOT IMPLEMENTED
    // function getApproved(uint256 _tokenId) public view returns (address _approved);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function implementsERC721() public view returns (bool _implementsERC721);
    function takeOwnership(uint256 _tokenId) public;
}

contract DetailedERC721 is ERC721 {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
}
