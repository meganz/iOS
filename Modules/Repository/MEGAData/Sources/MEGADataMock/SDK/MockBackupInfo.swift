import MEGAData
import MEGASdk

public final class MockBackupInfo: MEGABackupInfo {
    // MARK: - Identification
    private let identifier: Int
    private let backupName: String
    private let deviceIdentifier: String
    
    // MARK: - Handles
    private let rootHandle: MEGAHandle
    private let lastHandleSync: MEGAHandle
    
    // MARK: - Attributes
    private let backupType: MEGABackupType
    private let localFolderName: String
    private let extraInfo: String
    
    // MARK: - Current Status
    private let syncState: MEGASyncState
    private let backupSubstate: Int
    private let backupStatus: Int
    private let backupProgress: Int
    private let backupUploads: Int
    private let backupDownloads: Int
    
    // MARK: - Timestamps
    private let timestamp: Date
    private let activityTimestamp: Date
    
    public init(identifier: Int = 0, backupName: String = "", deviceIdentifier: String = "", rootHandle: MEGAHandle = .invalidHandle, lastHandleSync: MEGAHandle = .invalidHandle, backupType: MEGABackupType = .invalid, localFolderName: String = "", extraInfo: String = "", syncState: MEGASyncState = .unknown, backupSubstate: Int = 0, backupStatus: Int = 0, backupProgress: Int = 0, backupUploads: Int = 0, backupDownloads: Int = 0, timestamp: Date = Date(), activityTimestamp: Date = Date()) {
        self.identifier = identifier
        self.backupName = backupName
        self.deviceIdentifier = deviceIdentifier
        self.rootHandle = rootHandle
        self.lastHandleSync = lastHandleSync
        self.backupType = backupType
        self.localFolderName = localFolderName
        self.extraInfo = extraInfo
        self.syncState = syncState
        self.backupSubstate = backupSubstate
        self.backupStatus = backupStatus
        self.backupProgress = backupProgress
        self.backupUploads = backupUploads
        self.backupDownloads = backupDownloads
        self.timestamp = timestamp
        self.activityTimestamp = activityTimestamp
    }
    
    public override var id: UInt { UInt(identifier) }
    public override var name: String? { backupName }
    public override var deviceId: String? { deviceIdentifier }
    public override var root: UInt64 { rootHandle }
    public override var lastSync: UInt64 { lastHandleSync }
    public override var type: MEGABackupType { backupType }
    public override var localFolder: String? { localFolderName }
    public override var extra: String? { extraInfo }
    public override var state: MEGASyncState { syncState }
    public override var substate: UInt { UInt(backupSubstate) }
    public override var status: UInt { UInt(backupStatus) }
    public override var progress: UInt { UInt(backupProgress) }
    public override var uploads: UInt { UInt(backupUploads) }
    public override var downloads: UInt { UInt(backupDownloads) }
    public override var ts: Date { timestamp }
    public override var activityTs: Date { activityTimestamp }
}
