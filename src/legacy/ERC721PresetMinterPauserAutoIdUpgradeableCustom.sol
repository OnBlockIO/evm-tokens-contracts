// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoIdUpgradeableCustom is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721URIStorageUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) public virtual initializer {
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseTokenURI);
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant POLYNETWORK_ROLE = keccak256("POLYNETWORK_ROLE");

    CountersUpgradeable.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    function __ERC721PresetMinterPauserAutoId_init(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721PresetMinterPauserAutoId_init_unchained(baseTokenURI);
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721PresetMinterPauserAutoId_init_unchained(string memory baseTokenURI) internal initializer {
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(POLYNETWORK_ROLE, _msgSender());
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) internal virtual {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable) {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    /**
     * @dev polynetwork CrossChainNFTMapping
     */
    function mintWithURI(address to, uint256 tokenId, string memory uri) external {
        require(hasRole(POLYNETWORK_ROLE, _msgSender()), "mintWithURI: must have POLYNETWORK_ROLE role to mint");
        require(!_exists(tokenId), "token id already exist");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual override {
        super._safeMint(to, tokenId);
    }

    /**
     * @dev update tokenURI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenUri) internal virtual override {
        ERC721URIStorageUpgradeable._setTokenURI(tokenId, tokenUri);
    }

    function getCurrentCounter() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function getLastTokenID() public view returns (uint256) {
        if (_tokenIdTracker.current() == 1) {
            return _tokenIdTracker.current();
        } else return _tokenIdTracker.current() - 1;
    }

    function setBaseTokenURI(string memory baseTokenURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setBaseTokenURI: must have ADMIN role to change this");
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}
