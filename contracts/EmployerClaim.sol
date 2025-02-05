// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {PassportID} from "./PassportID.sol";
import {IdMapping} from "./IdMapping.sol";
// For Ethereum Sepolia
import { SepoliaZamaFHEVMConfig } from "fhevm/config/ZamaFHEVMConfig.sol";

contract EmployerClaim is Ownable2Step , SepoliaZamaFHEVMConfig {
    /// @dev Age threshold timestamp for adult verification (Jan 1, 2006 - 18 years on Jan 1, 2024)
    uint64 private constant AGE_THRESHOLD_TIMESTAMP = 1136070000;
    /// @dev Constant representing an invalid claim ID
    uint256 private constant INVALID_CLAIM = 0;
    euint64 private _AGE_THRESHOLD;
    euint16 private _REQUIRED_DEGREE;

    error InvalidClaimId();

    error InvalidContractAddress();

    error NotAuthorized();

    /// @dev Counter for tracking the latest claim ID
    uint64 public lastClaimId = 0;
    /// @dev Mapping of claim IDs to encrypted boolean results for adult claims
    mapping(uint64 => ebool) private adultClaims;
    /// @dev Mapping of user IDs to encrypted boolean results for verified claims
    mapping(uint256 => ebool) private verifiedClaims;

    event AdultClaimGenerated(uint64 claimId, uint256 userId);
  
    event DegreeClaimGenerated(uint64 claimId, uint256 userId);

    /// @dev Instance of IdMapping contract for user ID management
    IdMapping private idMapping;
    /// @dev Instance of PassportID contract for identity verification
    PassportID private passportContract;

    constructor(
        address _idMappingAddress,
        address _passportAddress
    ) Ownable(msg.sender) {
        // if (_idMappingAddress == address(0) || _passportAddress == address(0))
        //     revert InvalidContractAddress();

        idMapping = IdMapping(_idMappingAddress);
        passportContract = PassportID(_passportAddress);

        /// Set age threshold to 18 years (in Unix timestamp)
        _AGE_THRESHOLD = TFHE.asEuint64(AGE_THRESHOLD_TIMESTAMP);

        TFHE.allow(_AGE_THRESHOLD, address(this));
    }

    event BirthdateRetrieved(uint256 userId, euint64 birthdate);

    function generateAdultClaim(uint256 userId) public returns (uint64) {
        if (msg.sender != address(passportContract)) revert NotAuthorized();

        /// Retrieve the address associated with the user ID
        address addressToBeAllowed = idMapping.getAddr(userId);

        /// Retrieve the user's encrypted birthdate from the PassportID contract
        euint64 birthdate = (passportContract.getBirthdate(userId));

        lastClaimId++;

        /// Check if birthdate indicates user is over 18
        ebool isAdult = TFHE.le(birthdate, _AGE_THRESHOLD);

        /// Store the result of the claim
        adultClaims[lastClaimId] = isAdult;

        /// Grant access to the claim to both the contract and user for verification purposes
        TFHE.allow(isAdult, address(this));
        TFHE.allow(isAdult, addressToBeAllowed);

        /// Emit an event for the generated claim
        emit AdultClaimGenerated(lastClaimId, userId);

        return lastClaimId;
    }

    function getAdultClaim(uint64 claimId) public view returns (ebool) {
        if (claimId == 0 || claimId > lastClaimId) revert InvalidClaimId();
        return adultClaims[claimId];
    }

    function verifyClaims(uint256 userId, uint64 adultClaim) public {
        if (adultClaim == INVALID_CLAIM || adultClaim > lastClaimId)
            revert InvalidClaimId();

        ebool isAdult = adultClaims[adultClaim];

        ebool verify = isAdult;

        /// Store the verification result under the userId mapping
        verifiedClaims[userId] = verify;

        /// Grant access to the claim
        TFHE.allow(verify, address(this));
        TFHE.allow(verify, owner());
    }

    function getVerifyClaim(uint256 userId) public view returns (ebool) {
        return verifiedClaims[userId];
    }
}
