import Foundation

public struct BackupEntity: Sendable, Identifiable {
    // MARK: - Identification
    public let id: Int
    public let name: String
    public let deviceId: String
    
    // MARK: - Handles
    public let rootHandle: HandleEntity
    public let lastHandleSync: HandleEntity
    
    // MARK: - Attributes
    public let type: BackupTypeEntity
    public let localFolder: String
    public let extra: String
    
    // MARK: - Current Status
    public let syncState: SyncStateEntity
    public let substate: Int
    public let status: Int
    public let progress: Int
    public let uploads: Int
    public let downloads: Int
    
    // MARK: - Timestamps
    public let timestamp: Date
    public let activityTimestamp: Date
    
    public init(
        id: Int,
        name: String,
        deviceId: String,
        rootHandle: HandleEntity,
        lastHandleSync: HandleEntity,
        type: BackupTypeEntity,
        localFolder: String,
        extra: String,
        syncState: SyncStateEntity,
        substate: Int,
        status: Int,
        progress: Int,
        uploads: Int,
        downloads: Int,
        timestamp: Date,
        activityTimestamp: Date
    ) {
        self.id = id
        self.name = name
        self.deviceId = deviceId
        self.rootHandle = rootHandle
        self.lastHandleSync = lastHandleSync
        self.type = type
        self.localFolder = localFolder
        self.extra = extra
        self.syncState = syncState
        self.substate = substate
        self.status = status
        self.progress = progress
        self.uploads = uploads
        self.downloads = downloads
        self.timestamp = timestamp
        self.activityTimestamp = activityTimestamp
    }
}

extension BackupEntity: Equatable {
    public static func == (lhs: BackupEntity, rhs: BackupEntity) -> Bool {
        return lhs.id == rhs.id
    }
}
