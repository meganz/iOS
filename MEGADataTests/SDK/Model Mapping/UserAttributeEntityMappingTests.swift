@testable import MEGA
import MEGADomain
import XCTest

final class UserAttributeEntityMappingTests: XCTestCase {
    
    func testUserAttributeEntity_OnUpdateAttribute_shouldReturnCorrectMapping() {
        let sut: [UserAttributeEntity] = [.avatar, .firstName, .lastName, .authRing, .lastInteraction, .eD25519PublicKey, .cU25519PublicKey, .keyring, .sigRsaPublicKey, .sigCU255PublicKey, .language, .pwdReminder, .disableVersions, .contactLinkVerification, .richPreviews, .rubbishTime, .lastPSA, .storageState, .geolocation, .cameraUploadsFolder, .myChatFilesFolder, .pushSettings, .alias, .deviceNames, .backupsFolder, .cookieSettings, .jsonSyncConfigData, .drivesName, .noCallKit]
        
        for type in sut {
            switch type {
            case .avatar: XCTAssertEqual(type.toMEGAUserAttribute(), .avatar)
            case .firstName: XCTAssertEqual(type.toMEGAUserAttribute(), .firstname)
            case .lastName: XCTAssertEqual(type.toMEGAUserAttribute(), .lastname)
            case .authRing: XCTAssertEqual(type.toMEGAUserAttribute(), .authRing)
            case .lastInteraction: XCTAssertEqual(type.toMEGAUserAttribute(), .lastInteraction)
            case .eD25519PublicKey: XCTAssertEqual(type.toMEGAUserAttribute(), .ed25519PublicKey)
            case .cU25519PublicKey: XCTAssertEqual(type.toMEGAUserAttribute(), .cu25519PublicKey)
            case .keyring: XCTAssertEqual(type.toMEGAUserAttribute(), .keyring)
            case .sigRsaPublicKey: XCTAssertEqual(type.toMEGAUserAttribute(), .sigRsaPublicKey)
            case .sigCU255PublicKey: XCTAssertEqual(type.toMEGAUserAttribute(), .sigCU255PublicKey)
            case .language: XCTAssertEqual(type.toMEGAUserAttribute(), .language)
            case .pwdReminder: XCTAssertEqual(type.toMEGAUserAttribute(), .pwdReminder)
            case .disableVersions: XCTAssertEqual(type.toMEGAUserAttribute(), .disableVersions)
            case .contactLinkVerification: XCTAssertEqual(type.toMEGAUserAttribute(), .contactLinkVerification)
            case .richPreviews: XCTAssertEqual(type.toMEGAUserAttribute(), .richPreviews)
            case .rubbishTime: XCTAssertEqual(type.toMEGAUserAttribute(), .rubbishTime)
            case .lastPSA: XCTAssertEqual(type.toMEGAUserAttribute(), .lastPSA)
            case .storageState: XCTAssertEqual(type.toMEGAUserAttribute(), .storageState)
            case .geolocation: XCTAssertEqual(type.toMEGAUserAttribute(), .geolocation)
            case .cameraUploadsFolder: XCTAssertEqual(type.toMEGAUserAttribute(), .cameraUploadsFolder)
            case .myChatFilesFolder: XCTAssertEqual(type.toMEGAUserAttribute(), .myChatFilesFolder)
            case .pushSettings: XCTAssertEqual(type.toMEGAUserAttribute(), .pushSettings)
            case .alias: XCTAssertEqual(type.toMEGAUserAttribute(), .alias)
            case .deviceNames: XCTAssertEqual(type.toMEGAUserAttribute(), .deviceNames)
            case .backupsFolder: XCTAssertEqual(type.toMEGAUserAttribute(), .backupsFolder)
            case .cookieSettings: XCTAssertEqual(type.toMEGAUserAttribute(), .cookieSettings)
            case .jsonSyncConfigData: XCTAssertEqual(type.toMEGAUserAttribute(), .jsonSyncConfigData)
            case .drivesName: XCTAssertEqual(type.toMEGAUserAttribute(), .drivesName)
            case .noCallKit: XCTAssertEqual(type.toMEGAUserAttribute(), .noCallKit)
            case .appsPreferences: XCTAssertEqual(type.toMEGAUserAttribute(), .appsPreferences)
            case .contentConsumptionPreferences: XCTAssertEqual(type.toMEGAUserAttribute(), .contentConsumptionPreferences)
            case .lastReadNotification: XCTAssertEqual(type.toMEGAUserAttribute(), .lastReadNotification)
            }
        }
    }
}
