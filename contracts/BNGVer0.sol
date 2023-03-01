/*
                                    SPDX-License-Identifier: MIT

███    ███ ██    ██  ███  ███  ████████  ███   ██   ░████░    ▒████▒   ██    ██  ██   ███  ████████ 
░██▒  ▒██░ ██    ██  ███  ███  ████████  ███   ██   ██████   ▒██████   ██    ██  ██  ▓██   ████████ 
 ███  ███  ██    ██  ███▒▒███  ██        ███▒  ██  ▒██  ██▒  ██▒  ▒█   ██    ██  ██ ▒██▒   ██       
  ██▒▒██   ██    ██  ███▓▓███  ██        ████  ██  ██▒  ▒██  ██        ██    ██  ██░██▒    ██       
  ▓████▓   ██    ██  ██▓██▓██  ██        ██▒█▒ ██  ██    ██  ███▒      ██    ██  █████     ██       
   ████    ██    ██  ██▒██▒██  ███████   ██ ██ ██  ██    ██  ▒█████▒   ██    ██  █████     ███████  
   ▒██▒    ██    ██  ██░██░██  ███████   ██ ██ ██  ██    ██   ░█████▒  ██    ██  █████▒    ███████  
    ██     ██    ██  ██ ██ ██  ██        ██ ▒█▒██  ██    ██      ▒███  ██    ██  ██▒▒██    ██       
    ██     ██    ██  ██    ██  ██        ██  ████  ██▒  ▒██        ██  ██    ██  ██  ██▓   ██       
    ██     ██▓  ▓██  ██    ██  ██        ██  ▒███  ▒██  ██▒  █▒░  ▒██  ██▓  ▓██  ██  ▒██   ██       
    ██     ▒██████▒  ██    ██  ████████  ██   ███   ██████   ███████▒  ▒██████▒  ██   ██▓  ████████ 
    ██      ▒████▒   ██    ██  ████████  ██   ███   ░████░   ░█████▒    ▒████▒   ██   ▒██  ████████ 

                            Copyright 2023 Yumenosuke (Nexum Founder/CTO)
*/

pragma solidity >=0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

contract BNGVer0 is
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable
{
    using MerkleProofUpgradeable for bytes32[];
    using Base64Upgradeable for bytes;
    using StringsUpgradeable for uint256;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Bingo NFT", "BNG");
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __Ownable_init();

        // set correct values from deploy script!
        mintLimit = 0;
        isPublicMintPaused = true;
        isAllowlistMintPaused = true;
        publicPrice = 1 ether;
        allowListPrice = 0.01 ether;
        allowlistedMemberMintLimit = 1;
        _royaltyFraction = 0;
        _royaltyReceiver = msg.sender;
        _withdrawalReceiver = msg.sender;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721AUpgradeable, IERC721AUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////
    //// ERC2981
    ///////////////////////////////////////////////////////////////////

    uint96 private _royaltyFraction;

    /**
     * @dev set royalty in percentage x 100. e.g. 5% should be 500.
     */
    function setRoyaltyFraction(uint96 royaltyFraction) external onlyOwner {
        _royaltyFraction = royaltyFraction;
    }

    address private _royaltyReceiver;

    function setRoyaltyReceiver(address receiver) external onlyOwner {
        _royaltyReceiver = receiver;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override checkTokenIdExists(tokenId) returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyFraction) / 10_000;
    }

    ///////////////////////////////////////////////////////////////////
    //// URI
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Token URI
    //////////////////////////////////

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        checkTokenIdExists(tokenId)
        returns (string memory)
    {
        string memory svg = _svg(tokenId);
        bytes memory json = abi.encodePacked(
            '{"name": "#',
            tokenId.toString(),
            '", "description": "Bingo NFT is a full-on-chain BingoCard NFT.", "image": "data:image/svg+xml;base64,',
            bytes(svg).encode(),
            '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", json.encode()));
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Tokens
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Admin Mint
    //////////////////////////////////

    function adminMint(uint256 quantity) external onlyOwner checkMintLimit(quantity) {
        _safeMint(msg.sender, quantity);
    }

    function adminMintTo(address to, uint256 quantity) external onlyOwner checkMintLimit(quantity) {
        _safeMint(to, quantity);
    }

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    function publicMint(
        uint256 quantity
    ) external payable whenPublicMintNotPaused checkMintLimit(quantity) checkPay(publicPrice, quantity) {
        _safeMint(msg.sender, quantity);
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    function allowlistMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    )
        external
        payable
        whenAllowlistMintNotPaused
        checkAllowlist(merkleProof)
        checkAllowlistMintLimit(quantity)
        checkMintLimit(quantity)
        checkPay(allowListPrice, quantity)
    {
        _incrementAllowListMemberMintCount(msg.sender, quantity);
        _safeMint(msg.sender, quantity);
    }

    ///////////////////////////////////////////////////////////////////
    //// Minting Limit
    ///////////////////////////////////////////////////////////////////

    uint256 public mintLimit;

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    modifier checkMintLimit(uint256 quantity) {
        require(_totalMinted() + quantity <= mintLimit, "minting exceeds the limit");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Pricing
    ///////////////////////////////////////////////////////////////////

    modifier checkPay(uint256 price, uint256 quantity) {
        require(msg.value >= price * quantity, "not enough eth");
        _;
    }

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    uint256 public publicPrice;

    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    uint256 public allowListPrice;

    function setAllowListPrice(uint256 allowListPrice_) external onlyOwner {
        allowListPrice = allowListPrice_;
    }

    ///////////////////////////////////////////////////////////////////
    //// Allowlist
    ///////////////////////////////////////////////////////////////////

    //////////////////////////////////
    //// Verification
    //////////////////////////////////

    bytes32 private _merkleRoot;

    function setAllowlist(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function isAllowlisted(bytes32[] calldata merkleProof) public view returns (bool) {
        return merkleProof.verify(_merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    modifier checkAllowlist(bytes32[] calldata merkleProof) {
        require(isAllowlisted(merkleProof), "invalid merkle proof");
        _;
    }

    //////////////////////////////////
    //// Limit
    //////////////////////////////////

    uint256 public allowlistedMemberMintLimit;

    function setAllowlistedMemberMintLimit(uint256 quantity) external onlyOwner {
        allowlistedMemberMintLimit = quantity;
    }

    modifier checkAllowlistMintLimit(uint256 quantity) {
        require(
            allowListMemberMintCount(msg.sender) + quantity <= allowlistedMemberMintLimit,
            "allowlist minting exceeds the limit"
        );
        _;
    }

    //////////////////////////////////
    //// Aux
    //////////////////////////////////

    uint64 private constant _AUX_BITMASK_ADDRESS_DATA_ENTRY = (1 << 16) - 1;
    uint64 private constant _AUX_BITPOS_NUMBER_ALLOWLIST_MINTED = 0;

    function allowListMemberMintCount(address owner) public view returns (uint256) {
        return (_getAux(owner) >> _AUX_BITPOS_NUMBER_ALLOWLIST_MINTED) & _AUX_BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _incrementAllowListMemberMintCount(address owner, uint256 quantity) private {
        require(allowListMemberMintCount(owner) + quantity <= _AUX_BITMASK_ADDRESS_DATA_ENTRY, "quantity overflow");
        uint64 one = 1;
        uint64 aux = _getAux(owner) + uint64(quantity) * ((one << _AUX_BITPOS_NUMBER_ALLOWLIST_MINTED) | one);
        _setAux(owner, aux);
    }

    ///////////////////////////////////////////////////////////////////
    //// Pausing
    ///////////////////////////////////////////////////////////////////

    event PublicMintPaused();
    event PublicMintUnpaused();
    event AllowlistMintPaused();
    event AllowlistMintUnpaused();

    //////////////////////////////////
    //// Public Mint
    //////////////////////////////////

    bool public isPublicMintPaused;

    function pausePublicMint() external onlyOwner whenPublicMintNotPaused {
        isPublicMintPaused = true;
        emit PublicMintPaused();
    }

    function unpausePublicMint() external onlyOwner whenPublicMintPaused {
        isPublicMintPaused = false;
        emit PublicMintUnpaused();
    }

    modifier whenPublicMintNotPaused() {
        require(!isPublicMintPaused, "public mint: paused");
        _;
    }

    modifier whenPublicMintPaused() {
        require(isPublicMintPaused, "public mint: not paused");
        _;
    }

    //////////////////////////////////
    //// Allowlist Mint
    //////////////////////////////////

    bool public isAllowlistMintPaused;

    function pauseAllowlistMint() external onlyOwner whenAllowlistMintNotPaused {
        isAllowlistMintPaused = true;
        emit AllowlistMintPaused();
    }

    function unpauseAllowlistMint() external onlyOwner whenAllowlistMintPaused {
        isAllowlistMintPaused = false;
        emit AllowlistMintUnpaused();
    }

    modifier whenAllowlistMintNotPaused() {
        require(!isAllowlistMintPaused, "allowlist mint: paused");
        _;
    }

    modifier whenAllowlistMintPaused() {
        require(isAllowlistMintPaused, "allowlist mint: not paused");
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //// Withdraw
    ///////////////////////////////////////////////////////////////////

    address private _withdrawalReceiver;

    function setWithdrawalReceiver(address receiver) external onlyOwner {
        _withdrawalReceiver = receiver;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(_withdrawalReceiver).transfer(amount);
    }

    ///////////////////////////////////////////////////////////////////
    //// Logic
    ///////////////////////////////////////////////////////////////////

    function _numbers(uint256 tokenId) private pure returns (uint256[25] memory numbers) {
        uint256 k = uint256(keccak256(abi.encodePacked(tokenId)));
        for (uint256 i = 0; i < 25; i++) {
            if (i == 12) {
                // center is 0
                numbers[i] = 0;
                continue;
            }
            uint256 min = (i / 5) * 15 + 1;
            bool exist;
            uint n;
            do {
                exist = false;
                n = min + (k % 15);
                for (uint256 j = 0; j < i; j++) {
                    if (numbers[j] != n) continue;
                    exist = true;
                    break;
                }
                k /= 15;
            } while (exist);
            numbers[i] = n;
        }
    }

    ///////////////////////////////////////////////////////////////////
    //// SVG
    ///////////////////////////////////////////////////////////////////

    function _svg(uint256 tokenId) private pure returns (string memory result) {
        uint256[25] memory numbers = _numbers(tokenId);
        bytes memory data;
        data = abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg width="100%" height="100%" viewBox="0 0 380 380" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"><g id="Capa-1" serif:id="Capa 1"><path d="M34.38,95.444l0,242.14c0,11.998 9.726,21.725 21.725,21.725l267.106,-0c11.998,-0 21.725,-9.727 21.725,-21.725l0,-260.927l0,-0l0,-33.562c0,-11.998 -9.727,-21.725 -21.725,-21.725l-267.106,-0c-11.998,-0 -21.725,9.727 -21.725,21.725l0,52.349l0,-0Zm305.125,-0l0,242.14c0,8.984 -7.31,16.294 -16.294,16.294l-267.106,-0c-8.985,-0 -16.294,-7.31 -16.294,-16.294l0,-242.14l299.694,-0Z" style="fill:#312782;fill-rule:nonzero;"/><text x="80.673px" y="81.948px" style="font-family:\'GillSans-BoldItalic\', \'Gill Sans\', sans-serif;font-weight:700;font-style:italic;font-size:64px;fill:#fff;">BINGO</text><path d="M189.658,208.153l4.806,10.9l11.842,-1.288l-7.036,9.612l7.036,9.612l-11.842,-1.288l-4.806,10.9l-4.806,-10.9l-11.842,1.288l7.036,-9.612l-7.036,-9.612l11.842,1.288l4.806,-10.9Z" style="fill:#312782;fill-rule:nonzero;"/>'
        );
        for (uint i = 0; i < numbers.length; i++) {
            if (i == 12) continue;
            uint256 x = 49 + (i / 5) * 61;
            uint256 y = 131 + (i % 5) * 53;
            if (numbers[i] < 10) x += 10;
            data = abi.encodePacked(
                data,
                '<text x="',
                x.toString(),
                'px" y="',
                y.toString(),
                "px\" style=\"font-family:'GillSans-Bold', 'Gill Sans', sans-serif;font-weight:700;font-size:29.296px;\">",
                numbers[i].toString(),
                "</text>"
            );
        }
        data = abi.encodePacked(
            data,
            '<path d="M96.491,306.536l-0,-105.546l-62.111,0l-0,105.546l0,0l0,31.782c0,11.593 9.398,20.991 20.99,20.991l41.121,-0l0,-52.773l-0,-0Zm-1.629,1.629l0,49.514l-39.492,-0c-10.675,-0 -19.361,-8.685 -19.361,-19.361l0,-30.153l58.853,-0Zm-0,-3.259l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.773l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.629,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.629,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.772l-58.852,0l-0,-49.514l58.852,0l-0,49.514Z" style="fill:#312782;fill-rule:nonzero;"/><path d="M158.603,306.536l-62.111,0l-0,52.773l62.111,0l-0,-52.773Zm-1.63,51.143l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.63,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.63,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.773l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.63,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.63,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.772l-58.852,0l-0,-49.514l58.852,0l-0,49.514Z" style="fill:#312782;fill-rule:nonzero;"/><path d="M220.714,306.536l-62.111,0l-0,52.773l62.111,0l-0,-52.773Zm-1.63,51.143l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.63,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.63,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.773l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.63,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.63,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.772l-58.852,0l-0,-49.514l58.852,0l-0,49.514Z" style="fill:#312782;fill-rule:nonzero;"/><path d="M282.825,306.536l-62.111,0l-0,52.773l62.111,0l-0,-52.773Zm-1.629,51.143l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.629,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.629,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.773l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm1.629,-51.143l-0,-105.546l-62.111,0l-0,105.546l62.111,0Zm-1.629,-1.63l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.772l-58.852,0l-0,-49.514l58.852,0l-0,49.514Z" style="fill:#312782;fill-rule:nonzero;"/><path d="M282.825,95.444l-0,211.092l0,0l0,52.773l41.12,-0c11.593,-0 20.991,-9.398 20.991,-20.991l0,-31.782l-0,-0l-0,-211.092l-62.111,0Zm60.482,212.721l0,30.153c0,10.676 -8.686,19.361 -19.362,19.361l-39.491,-0l0,-49.514l58.853,-0Zm-0,-3.259l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.773l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.773l-58.852,0l-0,-49.514l58.852,0l-0,49.514Zm-0,-52.772l-58.852,0l-0,-49.514l58.852,0l-0,49.514Z" style="fill:#312782;fill-rule:nonzero;"/></g></svg>'
        );
        return string(data);
    }

    ///////////////////////////////////////////////////////////////////
    //// Utilities
    ///////////////////////////////////////////////////////////////////

    modifier checkTokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "tokenId not exist");
        _;
    }
}
