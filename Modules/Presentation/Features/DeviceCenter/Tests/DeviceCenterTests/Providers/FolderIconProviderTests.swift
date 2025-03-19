@testable import DeviceCenter
import MEGADomain
import Testing

@Suite("Folder Icon Provider Tests Suite - Testing icon mapping for backup types using arguments")
struct FolderIconProviderTestSuite {
    
    @Test("Returns expected icon for given backup type", arguments: [
        (BackupTypeEntity.backupUpload, "backupFolder"),
        (.cameraUpload, "cameraUploadsFolder"),
        (.mediaUpload, "cameraUploadsFolder"),
        (.downSync, "syncFolder"),
        (.twoWay, "syncFolder"),
        (.upSync, "syncFolder"),
        (.invalid, "syncFolder")
    ])
    func returnsExpectedIconForBackupType(
        backupType: BackupTypeEntity,
        expectedIcon: String
    ) {
        let sut = FolderIconProvider()
        #expect(sut.iconName(for: backupType) == expectedIcon, "Expected \(expectedIcon) for backup type \(backupType)")
    }
}
