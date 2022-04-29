// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IArchive.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IGovernance public gov;
    IArchive public archive;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event MatchedTx(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint256 payToSeller,
        address paymentToken,
        uint256 purchaseAmount,
        uint256 nonce,
        uint256 nftType,
        uint256 fee
    );

    event CancelSale(address indexed seller, uint256 nonce, bytes32 sigHash);
    event NativePayment(address indexed to, uint256 amount);

    modifier onlyManager() {
        require(gov.hasRole(MANAGER_ROLE, msg.sender), "Caller is not Manager");
        _;
    }

    constructor(address _gov, address _archive) {
        gov = IGovernance(_gov);
        archive = IArchive(_archive);
    }

    /**
        @notice Change a new Governance contract
        @dev Caller must have MANAGER_ROLE
        @param _newGov       Address of new Governance Contract
        Note: When `_gov = 0x00`, matchTransaction() and matchTransaction1155() will be deprecated
            Please set it wisely.
    */
    function setGov(address _newGov) external onlyManager {
        gov = IGovernance(_newGov);
    }

    /**
        @notice Change a new Archive contract
        @dev Caller must have MANAGER_ROLE
        @param _newArchive       Address of new Archive Contract
        Note: When `_archive = 0x00`, this Marketplace contract is deprecated permanently
            Please set it wisely.
    */
    function setArchive(address _newArchive) external onlyManager {
        archive = IArchive(_newArchive);
    }

    /**
        @notice Support Purchase NFT721 item
        @dev Caller can be ANY
        @param _addrs            A list of required addresses
            + _addrs[0]: Owner of NFT item
            + _addrs[1]: Address of NFT contract
            + _addrs[2]: Address of Payment Token contract (address 0x00 - Native Coin)
        @param _values           A list of required unsigned integer values
            + _values[0]: Number ID of Token
            + _values[1]: Payment amount
            + _values[2]: Nonce (a number provided by system)
    */
    function matchTransaction(
        address[3] calldata _addrs,
        uint256[3] calldata _values,
        bytes calldata _signature
    ) external payable nonReentrant {
        _precheck(_addrs[2], _values[1], _signature);

        IERC721 _nftContr = IERC721(_addrs[1]);
        require(
            _nftContr.ownerOf(_values[0]) == _addrs[0],
            "Item not owned by Seller"
        );

        bytes32 _msgHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _addrs[1],
                    _values[0],
                    _addrs[2],
                    _values[1],
                    _values[2]
                )
            )
        );
        _validateSig(_addrs[0], _msgHash, _signature);

        (address _buyer, uint256 _fee, uint256 _payToSeller) = _makePayment(
            _addrs[2],
            _addrs[0],
            _values[1]
        );
        _nftContr.safeTransferFrom(_addrs[0], _buyer, _values[0]);

        emit MatchedTx(
            _addrs[1],
            _values[0],
            _buyer,
            _addrs[0],
            _payToSeller,
            _addrs[2],
            1,
            _values[2],
            721,
            _fee
        );
    }

    /**
        @notice Support Purchase NFT1155 item
        @dev Caller can be ANY
        @param _addrs            A list of required addresses
            + _addrs[0]: Owner of NFT item
            + _addrs[1]: Address of NFT contract
            + _addrs[2]: Address of Payment Token contract (address 0x00 - Native Coin)
        @param _values           A list of required unsigned integer values
            + _values[0]: Number ID of Token
            + _values[1]: Payment amount    (total price)
            + _values[2]: Nonce (a number provided by system)
            + _values[3]: Purchase amount of items
    */
    function matchTransaction1155(
        address[3] calldata _addrs,
        uint256[4] calldata _values,
        bytes calldata _signature
    ) external payable nonReentrant {
        _precheck(_addrs[2], _values[1], _signature);

        IERC1155 _nftContr = IERC1155(_addrs[1]);
        require(
            _nftContr.balanceOf(_addrs[0], _values[0]) >= _values[3],
            "Insufficient items in stock"
        );

        bytes32 _msgHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _addrs[1],
                    _values[0],
                    _addrs[2],
                    _values[3],
                    _values[1],
                    _values[2]
                )
            )
        );
        _validateSig(_addrs[0], _msgHash, _signature);

        (address _buyer, uint256 _fee, uint256 _payToSeller) = _makePayment(
            _addrs[2],
            _addrs[0],
            _values[1]
        );
        _nftContr.safeTransferFrom(
            _addrs[0],
            _buyer,
            _values[0],
            _values[3],
            ""
        );

        emit MatchedTx(
            _addrs[1],
            _values[0],
            _buyer,
            _addrs[0],
            _payToSeller,
            _addrs[2],
            _values[3],
            _values[2],
            1155,
            _fee
        );
    }

    function _validateSig(
        address _signer,
        bytes32 _msgHash,
        bytes calldata _signature
    ) private pure {
        require(
            ECDSA.recover(_msgHash, _signature) == _signer,
            "Invalid params or signature"
        );
    }

    function _makePayment(
        address _paymentToken,
        address _seller,
        uint256 _paymentAmt
    )
        private
        returns (
            address _buyer,
            uint256 _fee,
            uint256 _payToSeller
        )
    {
        (_fee, _payToSeller) = _calculate(_paymentAmt);

        _buyer = msg.sender;
        if (_fee != 0) _payment(_paymentToken, _buyer, gov.treasury(), _fee);
        _payment(_paymentToken, _buyer, _seller, _payToSeller);
    }

    function _precheck(
        address _paymentToken,
        uint256 _paymentAmt,
        bytes calldata _signature
    ) private {
        //  save Hash of signature into Archive contract
        //  if the signature has been used before -> revert
        archive.record(keccak256(_signature));

        if (_paymentToken == address(0))
            require(msg.value == _paymentAmt, "Insufficient payment");
        else require(gov.paymentTokens(_paymentToken), "Payment not supported");
    }

    function _calculate(uint256 _price)
        private
        view
        returns (uint256 _fee, uint256 _payToSeller)
    {
        //  fee_rate = commissionFee / FEE_DENOMINATOR   with FEE_DENOMINATOR = 10^4
        _fee = (_price * gov.commissionFee()) / gov.FEE_DENOMINATOR();
        _payToSeller = _price - _fee;
    }

    function _payment(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        if (_token != address(0))
            IERC20(_token).safeTransferFrom(_from, _to, _amount);
        else _transfer(payable(_to), _amount);
    }

    function _transfer(address payable _to, uint256 _amount) private {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Payment transfer failed");
        emit NativePayment(_to, _amount);
    }

    /**
        @notice Cancel and record signature of one Sale
        @dev Caller can be ANY
        @param _addrs            A list of required addresses
            + _addrs[0]: Address was provided to generate `OnSale` signature
            + _addrs[1]: Address of NFT contract
            + _addrs[2]: Address of Payment Token contract (address 0x00 - Native Coin)
        @param _values           A list of required unsigned integer values
            + _values[0]: Number ID of Token
            + _values[1]: Payment amount    (total price)
            + _values[2]: Nonce (a number provided by system)
            + _values[3]: Purchase amount of items (NFT = 721 -> leave empty)
    */
    function cancelSale(
        uint256 _type,
        address[3] calldata _addrs,
        uint256[4] calldata _values,
        bytes calldata _signature
    ) external {
        require(_addrs[0] == msg.sender, "Seller not matched");
        require(_type == 721 || _type == 1155, "Invalid type of NFT");

        bytes32 _sigHash = keccak256(_signature);
        archive.record(_sigHash);
        bytes32 _msgHash;
        if (_type == 721)
            _msgHash = ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        _addrs[1],
                        _values[0],
                        _addrs[2],
                        _values[1],
                        _values[2]
                    )
                )
            );
        else
            _msgHash = ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        _addrs[1],
                        _values[0],
                        _addrs[2],
                        _values[3],
                        _values[1],
                        _values[2]
                    )
                )
            );
        _validateSig(_addrs[0], _msgHash, _signature);

        emit CancelSale(_addrs[0], _values[2], _sigHash);
    }

    /***
     @dev Caller is owner. Use to withdraw any ERC20 token send to contract
     */
    function withdrawAnyERC20Token(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}
