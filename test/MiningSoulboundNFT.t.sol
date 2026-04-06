// SPDX-License-Identifier: UNLICENSED
pragma solidity ^1.1.2;

import "spark-std/Test.sol";
import "openzeppelin-contracts-upgradeable/src/mocks/proxy/ERC1967Proxy.sol";

import "../src/MiningSoulboundNFT.sol";

contract MiningSoulboundNFTV2 is MiningSoulboundNFT {
    function version() external pure returns (uint256) {
        return 2;
    }
}

contract MiningSoulboundNFTTest is Test {
    MiningSoulboundNFT private _implementation;
    MiningSoulboundNFT private _token;

    address private _owner;
    address private _minter;
    address private _user;
    address private _other;
    string private _contractUri;

    function setUp() public {
        _owner = makeAddr("owner");
        _minter = makeAddr("minter");
        _user = makeAddr("user");
        _other = makeAddr("other");
        _contractUri = "ipfs://bafybeigdyrzt5example/metadata.json";

        _implementation = new MiningSoulboundNFT();

        bytes memory initData =
            abi.encodeWithSelector(MiningSoulboundNFT.initialize.selector, "Mining NFT", "MNFT", _contractUri);

        vm.prank(_owner);
        ERC1967ProxyMock proxy = new ERC1967ProxyMock(address(_implementation), initData);
        _token = MiningSoulboundNFT(address(proxy));
    }

    function testInitializeSetsOwnerAndMetadata() public {
        assertEq(_token.owner(), _owner);
        assertEq(_token.name(), "Mining NFT");
        assertEq(_token.symbol(), "MNFT");
        vm.prank(_owner);
        _token.setMinter(_minter, true);
        vm.prank(_minter);
        _token.mint(_user, block.timestamp + 1 days);
        assertEq(_token.tokenURI(1), _contractUri);
    }

    function testInitializeCannotRunTwice() public {
        vm.prank(_owner);
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        _token.initialize("Other", "OTR", "ipfs://other");
    }

    function testOwnerCanManageMinters() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);
        assertTrue(_token.minters(_minter));

        vm.prank(_owner);
        _token.setMinter(_minter, false);
        assertFalse(_token.minters(_minter));
    }

    function testNonOwnerCannotManageMinters() public {
        vm.prank(_other);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        _token.setMinter(_minter, true);
    }

    function testMintStoresExpirationAndLastValidDay() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);

        uint256 expirationDate = block.timestamp + 30 days;

        vm.prank(_minter);
        uint256 tokenId = _token.mint(_user, expirationDate);

        assertEq(tokenId, 1);
        assertEq(_token.ownerOf(tokenId), _user);
        assertEq(_token.balanceOf(_user), 1);
        assertEq(_token.expirationDateOf(tokenId), expirationDate);
        assertEq(_token.tokenURI(tokenId), _contractUri);
        assertEq(_token.lastValidDay(_user), expirationDate);
    }

    function testLastValidDayTracksMaximumExpiration() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);

        uint256 firstExpiration = block.timestamp + 10 days;
        uint256 secondExpiration = block.timestamp + 5 days;
        uint256 thirdExpiration = block.timestamp + 20 days;

        vm.startPrank(_minter);
        _token.mint(_user, firstExpiration);
        _token.mint(_user, secondExpiration);
        _token.mint(_user, thirdExpiration);
        vm.stopPrank();

        assertEq(_token.lastValidDay(_user), thirdExpiration);
        assertEq(_token.balanceOf(_user), 3);
    }

    function testLastValidDayCanRemainInPast() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);

        uint256 pastExpiration = block.timestamp - 1;

        vm.prank(_minter);
        _token.mint(_user, pastExpiration);

        assertEq(_token.lastValidDay(_user), pastExpiration);
    }

    function testOnlyMinterCanMint() public {
        vm.expectRevert(bytes("MiningSoulboundNFT: caller is not a minter"));
        _token.mint(_user, block.timestamp + 1 days);
    }

    function testTransferFromReverts() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);

        vm.prank(_minter);
        _token.mint(_user, block.timestamp + 1 days);

        vm.prank(_user);
        vm.expectRevert(bytes("MiningSoulboundNFT: transfers disabled"));
        _token.transferFrom(_user, _other, 1);
    }

    function testSafeTransferFromReverts() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);

        vm.prank(_minter);
        _token.mint(_user, block.timestamp + 1 days);

        vm.prank(_user);
        vm.expectRevert(bytes("MiningSoulboundNFT: transfers disabled"));
        _token.safeTransferFrom(_user, _other, 1);
    }

    function testApprovalsAreDisabled() public {
        vm.prank(_owner);
        _token.setMinter(_minter, true);

        vm.prank(_minter);
        _token.mint(_user, block.timestamp + 1 days);

        vm.prank(_user);
        vm.expectRevert(bytes("MiningSoulboundNFT: approvals disabled"));
        _token.approve(_other, 1);

        vm.prank(_user);
        vm.expectRevert(bytes("MiningSoulboundNFT: approvals disabled"));
        _token.setApprovalForAll(_other, true);
    }

    function testOnlyOwnerCanUpgrade() public {
        MiningSoulboundNFTV2 upgradedImplementation = new MiningSoulboundNFTV2();

        vm.prank(_other);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        _token.upgradeTo(address(upgradedImplementation));
    }

    function testOwnerCanUpgrade() public {
        MiningSoulboundNFTV2 upgradedImplementation = new MiningSoulboundNFTV2();

        vm.prank(_owner);
        _token.upgradeTo(address(upgradedImplementation));

        assertEq(MiningSoulboundNFTV2(address(_token)).version(), 2);
    }
}
