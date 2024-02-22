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
    
    /// If the user has never activated Camera Uploads on the current device (the current device being an iPhone or an iPad), a new item is created on the fly in the list of devices, referring to the current device, with status "no camera uploads" and with limited actions as that device is not currently part of the devices returned by the SDK. When the user activates the CU for the first time on that device, it becomes part of the devices provided by the SDK.
    public func isNewDeviceWithoutCU(currentUUID: String) -> Bool {
        id == currentUUID && status == .noCameraUploads
    }
}
