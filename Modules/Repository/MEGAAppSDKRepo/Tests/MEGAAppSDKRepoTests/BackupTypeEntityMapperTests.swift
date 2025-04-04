import MEGAAppSDKRepo
import MEGASdk
import XCTest

final class BackupTypeMappingTests: XCTestCase {
    
    func testBackupTypeEntity_OnUpdateType_shouldReturnCorrectMapping() {
        let sut: [MEGABackupType] = [.invalid, .twoWay, .upSync, .downSync, .cameraUpload, .mediaUpload, .backupUpload]
        
        for type in sut {
            switch type {
            case .invalid: XCTAssertEqual(type.toBackupTypeEntity(), .invalid)
            case .twoWay: XCTAssertEqual(type.toBackupTypeEntity(), .twoWay)
            case .upSync: XCTAssertEqual(type.toBackupTypeEntity(), .upSync)
            case .downSync: XCTAssertEqual(type.toBackupTypeEntity(), .downSync)
            case .cameraUpload: XCTAssertEqual(type.toBackupTypeEntity(), .cameraUpload)
            case .mediaUpload: XCTAssertEqual(type.toBackupTypeEntity(), .mediaUpload)
            case .backupUpload: XCTAssertEqual(type.toBackupTypeEntity(), .backupUpload)
            default: break
            }
        }
    }
}
