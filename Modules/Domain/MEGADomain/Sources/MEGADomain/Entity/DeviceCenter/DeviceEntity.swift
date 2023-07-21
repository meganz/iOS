import Foundation

public struct DeviceEntity: Sendable, Identifiable {
    public let id: String
    public let name: String
    
    public var backups: [BackupEntity]?
    public var status: BackupStatusEntity?
    public var updatingPercentage: Int?
    
    public init(
        id: String,
        name: String,
        backups: [BackupEntity]? = nil,
        status: BackupStatusEntity? = nil
    ) {
        self.id = id
        self.name = name
        self.backups = backups
        self.status = status
    }
    
    public func isMobileDevice() -> Bool {
        guard let backups else { return false }
        
        return backups.contains {
            $0.type == .cameraUpload || $0.type == .mediaUpload
        }
    }
}
