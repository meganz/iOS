@testable import MEGA
import MEGADomain
import XCTest

final class ChangeTypeEntityMapperTests: XCTestCase {
    
    func testChangeTypeMapper() {
        let sut: [MEGAUserChangeType] = [
            .auth,
            .lstint,
            .avatar,
            .firstname,
            .lastname,
            .email,
            .keyring,
            .country,
            .birthday,
            .pubKeyCu255,
            .pubKeyEd255,
            .sigPubKeyRsa,
            .sigPubKeyCu255,
            .language,
            .pwdReminder,
            .disableVersions,
            .contactLinkVerification,
            .richPreviews,
            .rubbishTime,
            .storageState,
            .geolocation,
            .cameraUploadsFolder,
            .myChatFilesFolder,
            .pushSettings,
            .userAlias,
            .unshareableKey,
            .deviceNames,
            .backupFolder,
            .cookieSetting,
            .noCallKit
        ]
        
        for type in sut {
            let entity = type.toChangeTypeEntity()
            switch type {
            case .auth:
                XCTAssertEqual(entity, .authentication)
            case .lstint:
                XCTAssertEqual(entity, .lastInteractionTime)
            case .avatar:
                XCTAssertEqual(entity, .avatar)
            case .firstname:
                XCTAssertEqual(entity, .firstname)
            case .lastname:
                XCTAssertEqual(entity, .lastname)
            case .email:
                XCTAssertEqual(entity, .email)
            case .keyring:
                XCTAssertEqual(entity, .keyring)
            case .country:
                XCTAssertEqual(entity, .country)
            case .birthday:
                XCTAssertEqual(entity, .birthday)
            case .pubKeyCu255:
                XCTAssertEqual(entity, .publicKeyForChat)
            case .pubKeyEd255:
                XCTAssertEqual(entity, .publicKeyForSigning)
            case .sigPubKeyRsa:
                XCTAssertEqual(entity, .signatureForRSAPublicKey)
            case .sigPubKeyCu255:
                XCTAssertEqual(entity, .signatureForCu25519PublicKey)
            case .language:
                XCTAssertEqual(entity, .language)
            case .pwdReminder:
                XCTAssertEqual(entity, .passwordReminder)
            case .disableVersions:
                XCTAssertEqual(entity, .disableVersions)
            case .contactLinkVerification:
                XCTAssertEqual(entity, .contactLinkVerification)
            case .richPreviews:
                XCTAssertEqual(entity, .richPreviews)
            case .rubbishTime:
                XCTAssertEqual(entity, .rubbishTimeForAutopurge)
            case .storageState:
                XCTAssertEqual(entity, .storageState)
            case .geolocation:
                XCTAssertEqual(entity, .geolocation)
            case .cameraUploadsFolder:
                XCTAssertEqual(entity, .cameraUploadsFolder)
            case .myChatFilesFolder:
                XCTAssertEqual(entity, .myChatFilesFolder)
            case .pushSettings:
                XCTAssertEqual(entity, .pushSettings)
            case .userAlias:
                XCTAssertEqual(entity, .userAlias)
            case .unshareableKey:
                XCTAssertEqual(entity, .unshareableKey)
            case .deviceNames:
                XCTAssertEqual(entity, .deviceNames)
            case .backupFolder:
                XCTAssertEqual(entity, .backupFolder)
            case .cookieSetting:
                XCTAssertEqual(entity, .cookieSetting)
            case .noCallKit:
                XCTAssertEqual(entity, .NoCallKit)
            case .appsPrefs:
                XCTAssertEqual(entity, .AppPrefs)
            case .ccPrefs:
                XCTAssertEqual(entity, .CCPrefs)
            @unknown default:
                XCTFail("Please map the new MEGAUserChangeType to UserEntity.ChangeTypeEntity")
            }
        }
    }
    
    func testMEGANodeChangeTypeMapping_forAllChangeTypes_shouldReturnCorrectChangeTypeEntity() {
        let megaNodeChangeTypes: [(MEGANodeChangeType, ChangeTypeEntity)] = [
            (.removed, .removed),
            (.attributes, .attributes),
            (.owner, .owner),
            (.timestamp, .timestamp),
            (.fileAttributes, .fileAttributes),
            (.inShare, .inShare),
            (.outShare, .outShare),
            (.parent, .parent),
            (.pendingShare, .pendingShare),
            (.publicLink, .publicLink),
            (.new, .new),
            (.name, .name),
            (.favourite, .favourite),
            (.sensitive, .sensitive)
        ]
        
        for (index, sut) in megaNodeChangeTypes.enumerated() {
            let (megaNodeChangeType, expectedResult) = sut
            
            XCTAssertEqual(
                ChangeTypeEntity(rawValue: megaNodeChangeType.rawValue),
                expectedResult,
                "Failed to testcase at index: \(index)")
        }
    }
}
