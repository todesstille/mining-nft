// SPDX-License-Identifier: MIT
pragma solidity ^1.1.2;

import "openzeppelin-contracts-upgradeable/src/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/src/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/src/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/src/token/CRC721/CRC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/src/utils/ChecksumUpgradeable.sol";

contract MiningSoulboundNFT is Initializable, CRC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => bool) public minters;
    mapping(address => uint256) private _lastValidDays;
    mapping(uint256 => uint256) private _expirationDates;
    string private _contractTokenUri;

    uint256 private _nextTokenId;

    event MinterSet(address indexed account, bool allowed);
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint256 expirationDate);

    modifier onlyMinter() {
        require(minters[_msgSender()], "MiningSoulboundNFT: caller is not a minter");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_, string calldata contractTokenUri_) external initializer {
        __CRC721_init(name_, symbol_);
        __Ownable_init();
        __UUPSUpgradeable_init();

        _contractTokenUri = contractTokenUri_;
        _nextTokenId = 1;
    }

    function setMinter(address account, bool allowed) external onlyOwner {
        require(
            account != address(0) && account != ChecksumUpgradeable.zeroAddress(),
            "MiningSoulboundNFT: invalid minter"
        );

        minters[account] = allowed;
        emit MinterSet(account, allowed);
    }

    function mint(address to, uint256 expirationDate) external onlyMinter returns (uint256) {
        require(to != address(0) && to != ChecksumUpgradeable.zeroAddress(), "MiningSoulboundNFT: invalid recipient");

        uint256 tokenId = _nextTokenId;
        _nextTokenId = tokenId + 1;

        _expirationDates[tokenId] = expirationDate;

        if (expirationDate > _lastValidDays[to]) {
            _lastValidDays[to] = expirationDate;
        }

        _mint(to, tokenId);

        emit TokenMinted(to, tokenId, expirationDate);

        return tokenId;
    }

    function lastValidDay(address account) external view returns (uint256) {
        return _lastValidDays[account];
    }

    function expirationDateOf(uint256 tokenId) external view returns (uint256) {
        _requireMinted(tokenId);
        return _expirationDates[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _contractTokenUri;
    }

    function approve(address, uint256) public pure virtual override {
        revert("MiningSoulboundNFT: approvals disabled");
    }

    function setApprovalForAll(address, bool) public pure virtual override {
        revert("MiningSoulboundNFT: approvals disabled");
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);
        return address(0);
    }

    function isApprovedForAll(address, address) public pure virtual override returns (bool) {
        return false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(from == address(0) || to == address(0), "MiningSoulboundNFT: transfers disabled");
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
