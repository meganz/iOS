import Foundation

public struct BackupEntity: Sendable, Identifiable {
    // MARK: - Identification
    public let id: Int
    public let name: String
    public let deviceId: String
    public let userAgent: String
    
    // MARK: - Handles
    public let rootHandle: HandleEntity
    public let lastHandleSync: HandleEntity
    
    // MARK: - Attributes
    public let type: BackupTypeEntity
    public let localFolder: String
    public let extra: String
    
    // MARK: - Current Status
    public let syncState: BackUpStateEntity
    public let substate: BackUpSubStateEntity
    public let status: BackupHeartbeatStatusEntity
    public let progress: UInt
    public let uploads: UInt
    public let downloads: UInt
    public var backupStatus: BackupStatusEntity?
    public var errorState: Int?
    
    // MARK: - Timestamps
    public let timestamp: Date?
    public let activityTimestamp: Date?
    
    public var isMobileBackup: Bool {
        type == .mediaUpload || type == .cameraUpload
    }
    
    /// The last heartbeat timestamp (in seconds since 1970) from either timestamp or activityTimestamp.
    public var lastBackupHeartbeat: TimeInterval {
        max(timestamp?.timeIntervalSince1970 ?? 0,
            activityTimestamp?.timeIntervalSince1970 ?? 0)
    }
    
    public var isTwoWayPaused: Bool {
        type == .twoWay && syncState.isPaused
    }
    
    public var isUploadPaused: Bool {
        type.isUpload() && (syncState == .pauseUp || syncState == .pauseFull)
    }
    
    public var isDownSyncPaused: Bool {
        type == .downSync && (syncState == .pauseDown || syncState == .pauseFull)
    }
    
    public var isPaused: Bool {
        isTwoWayPaused || isUploadPaused || isDownSyncPaused
    }
    
    public init(
        id: Int,
        name: String,
        deviceId: String,
        userAgent: String,
        rootHandle: HandleEntity,
        lastHandleSync: HandleEntity,
        type: BackupTypeEntity,
        localFolder: String,
        extra: String,
        syncState: BackUpStateEntity,
        substate: BackUpSubStateEntity,
        status: BackupHeartbeatStatusEntity,
        progress: UInt,
        uploads: UInt,
        downloads: UInt,
        timestamp: Date?,
        activityTimestamp: Date?
    ) {
        self.id = id
        self.name = name
        self.deviceId = deviceId
        self.userAgent = userAgent
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
    
    /// Returns the time (in seconds) since the last backup heartbeat based on a given reference time.
    public func timeSinceLastInteraction(from currentTime: TimeInterval = Date().timeIntervalSince1970) -> TimeInterval {
        currentTime - lastBackupHeartbeat
    }
    
    /// Determines if the elapsed time since the last backup interaction exceeds the allowed threshold.
    ///
    /// The allowed threshold (`maxInterval`) is defined in minutes and varies based on the backup type:
    /// - **Mobile Backups** (e.g. mediaUpload, cameraUpload): A maximum interval of **60 minutes**.
    /// - **Other Backups or syncs**: A maximum interval of **30 minutes**.
    ///
    /// - Parameter currentTime: The reference time (in seconds since 1970) used to compute the elapsed time. Defaults to the current time.
    /// - Returns: `true` if the elapsed time exceeds the allowed threshold, otherwise `false`.
    public func lastInteractionOutOfRange(from currentTime: TimeInterval = Date().timeIntervalSince1970) -> Bool {
        let maxInterval: TimeInterval = isMobileBackup ? 3600.0 : 1800.0
        return timeSinceLastInteraction(from: currentTime) > maxInterval
    }
}

extension BackupEntity: Equatable {
    public static func == (lhs: BackupEntity, rhs: BackupEntity) -> Bool {
        return lhs.id == rhs.id
    }
}
