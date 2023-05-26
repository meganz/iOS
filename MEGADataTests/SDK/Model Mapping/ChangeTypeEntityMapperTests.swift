import XCTest
import MEGADomain
@testable import MEGA

final class ChangeTypeEntityMapperTests: XCTestCase {
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
    
    func testChangeTypeMapper() {
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
            @unknown default:
                XCTFail("Please map the new MEGAUserChangeType to UserEntity.ChangeTypeEntity")
            }
        }
    }
}
