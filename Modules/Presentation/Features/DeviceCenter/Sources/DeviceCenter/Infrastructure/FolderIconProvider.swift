import MEGADomain
import SwiftUI

public protocol FolderIconProviding {
    func iconName(for backupType: BackupTypeEntity) -> String?
}

public final class FolderIconProvider: FolderIconProviding {
    private let iconMapping: [BackupTypeEntity: String] = [
        .backupUpload: "backupFolder",
        .cameraUpload: "cameraUploadsFolder",
        .mediaUpload: "cameraUploadsFolder",
        .downSync: "syncFolder",
        .twoWay: "syncFolder",
        .upSync: "syncFolder",
        .invalid: "syncFolder"
    ]
    
    public init() {}
    
    public func iconName(for backupType: BackupTypeEntity) -> String? {
        iconMapping[backupType]
    }
}
