// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IToken is IERC20, IERC20Permit {}

contract PermitTransfer {
    using ECDSA for bytes32;

    struct PermitData {
        address owner;
        uint256 value;
        uint256 deadline;
    }

    struct TransferData {
        IToken token;
        address to;
        uint256 amount;
    }

    function permittedTransferFrom(
        PermitData memory permitData,
        TransferData memory transferData,
        bytes memory permitSignature,
        bytes memory transferSignature
    ) public {
        require(permitData.owner != transferData.to, "PermitTransfer: owner and recipient are the same");
        require(
            permitData.owner != address(0) && transferData.to != address(0),
            "PermitTransfer: recipient/owner cannot be zero address"
        );

        bytes32 transferHash = keccak256(
            abi.encode(
                keccak256("Transfer(address token,address to,uint256 amount,uint256 nonce)"),
                transferData.token,
                transferData.to,
                transferData.amount,
                transferData.token.nonces(permitData.owner)
            )
        );
        address signer = transferHash.recover(transferSignature);
        require(signer == permitData.owner, "PermitTransfer: invalid transfer signature");
        require(permitData.value >= transferData.amount, "PermitTransfer: insufficient permit value");

        (bytes32 r, bytes32 s, uint8 v) = decodeSignature(permitSignature);

        transferData.token.permit(permitData.owner, address(this), permitData.value, permitData.deadline, v, r, s);
        transferData.token.transferFrom(permitData.owner, transferData.to, transferData.amount);
    }

    function decodeSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "PermitTransfer: invalid signature length");
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }
}
