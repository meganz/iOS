import MEGADomain
import MEGASdk

extension BackUpSubState {
    public func toBackupSubstateEntity() -> BackUpSubStateEntity {
        switch self {
        case .invalid: return .invalid
        case .noSyncError: return .noSyncError
        case .unknownError: return .unknownError
        case .unsupportedFileSystem: return .unsupportedFileSystem
        case .invalidRemoteType: return .invalidRemoteType
        case .invalidLocalType: return .invalidLocalType
        case .initialScanFailed: return .initialScanFailed
        case .localPathTemporaryUnavailable: return .localPathTemporaryUnavailable
        case .localPathUnavailable: return .localPathUnavailable
        case .remoteNodeNotFound: return .remoteNodeNotFound
        case .storageOverquota: return .storageOverquota
        case .accountExpired: return .accountExpired
        case .foreignTargetOverstorage: return .foreignTargetOverstorage
        case .remotePathHasChanged: return .remotePathHasChanged
        case .shareNonFullAccess: return .shareNonFullAccess
        case .localFilesystemMismatch: return .localFilesystemMismatch
        case .putNodesError: return .putNodesError
        case .activeSyncBelowPath: return .activeSyncBelowPath
        case .activeSyncAbovePath: return .activeSyncAbovePath
        case .remoteNodeMovedToRubbish: return .remoteNodeMovedToRubbish
        case .remoteNodeInsideRubbish: return .remoteNodeInsideRubbish
        case .vBoxSharedFolderUnsupported: return .vBoxSharedFolderUnsupported
        case .localPathSyncCollision: return .localPathSyncCollision
        case .accountBlocked: return .accountBlocked
        case .unknownTemporaryError: return .unknownTemporaryError
        case .tooManyActionPackets: return .tooManyActionPackets
        case .loggedOut: return .loggedOut
        case .wholeAccountRefetched: return .wholeAccountRefetched
        case .missingParentNode: return .missingParentNode
        case .backupModified: return .backupModified
        case .backupSourceNotBelowDrive: return .backupSourceNotBelowDrive
        case .syncConfigWriteFailure: return .syncConfigWriteFailure
        case .activeSyncSamePath: return .activeSyncSamePath
        case .couldNotMoveCloudNodes: return .couldNotMoveCloudNodes
        case .couldNotCreateIgnoreFile: return .couldNotCreateIgnoreFile
        case .syncConfigReadFailure: return .syncConfigReadFailure
        case .unknownDrivePath: return .unknownDrivePath
        case .invalidScanInterval: return .invalidScanInterval
        case .notificationSystemUnavailable: return .notificationSystemUnavailable
        case .unableToAddWatch: return .unableToAddWatch
        case .unableToRetrieveRootFSID: return .unableToRetrieveRootFSID
        case .unableToOpenDatabase: return .unableToOpenDatabase
        case .insufficientDiskSpace: return .insufficientDiskSpace
        case .failureAccessingPersistentStorage: return .failureAccessingPersistentStorage
        case .mismatchOfRootRSID: return .mismatchOfRootRSID
        case .filesystemFileIdsAreUnstable: return .filesystemFileIdsAreUnstable
        case .filesystemIDUnavailable: return .filesystemIDUnavailable
        @unknown default: return .unknownError
        }
    }
}

extension BackUpSubStateEntity {
    public func toBackUpSubState() -> BackUpSubState {
        switch self {
        case .invalid: return .invalid
        case .noSyncError: return .noSyncError
        case .unknownError: return .unknownError
        case .unsupportedFileSystem: return .unsupportedFileSystem
        case .invalidRemoteType: return .invalidRemoteType
        case .invalidLocalType: return .invalidLocalType
        case .initialScanFailed: return .initialScanFailed
        case .localPathTemporaryUnavailable: return .localPathTemporaryUnavailable
        case .localPathUnavailable: return .localPathUnavailable
        case .remoteNodeNotFound: return .remoteNodeNotFound
        case .storageOverquota: return .storageOverquota
        case .accountExpired: return .accountExpired
        case .foreignTargetOverstorage: return .foreignTargetOverstorage
        case .remotePathHasChanged: return .remotePathHasChanged
        case .shareNonFullAccess: return .shareNonFullAccess
        case .localFilesystemMismatch: return .localFilesystemMismatch
        case .putNodesError: return .putNodesError
        case .activeSyncBelowPath: return .activeSyncBelowPath
        case .activeSyncAbovePath: return .activeSyncAbovePath
        case .remoteNodeMovedToRubbish: return .remoteNodeMovedToRubbish
        case .remoteNodeInsideRubbish: return .remoteNodeInsideRubbish
        case .vBoxSharedFolderUnsupported: return .vBoxSharedFolderUnsupported
        case .localPathSyncCollision: return .localPathSyncCollision
        case .accountBlocked: return .accountBlocked
        case .unknownTemporaryError: return .unknownTemporaryError
        case .tooManyActionPackets: return .tooManyActionPackets
        case .loggedOut: return .loggedOut
        case .wholeAccountRefetched: return .wholeAccountRefetched
        case .missingParentNode: return .missingParentNode
        case .backupModified: return .backupModified
        case .backupSourceNotBelowDrive: return .backupSourceNotBelowDrive
        case .syncConfigWriteFailure: return .syncConfigWriteFailure
        case .activeSyncSamePath: return .activeSyncSamePath
        case .couldNotMoveCloudNodes: return .couldNotMoveCloudNodes
        case .couldNotCreateIgnoreFile: return .couldNotCreateIgnoreFile
        case .syncConfigReadFailure: return .syncConfigReadFailure
        case .unknownDrivePath: return .unknownDrivePath
        case .invalidScanInterval: return .invalidScanInterval
        case .notificationSystemUnavailable: return .notificationSystemUnavailable
        case .unableToAddWatch: return .unableToAddWatch
        case .unableToRetrieveRootFSID: return .unableToRetrieveRootFSID
        case .unableToOpenDatabase: return .unableToOpenDatabase
        case .insufficientDiskSpace: return .insufficientDiskSpace
        case .failureAccessingPersistentStorage: return .failureAccessingPersistentStorage
        case .mismatchOfRootRSID: return .mismatchOfRootRSID
        case .filesystemFileIdsAreUnstable: return .filesystemFileIdsAreUnstable
        case .filesystemIDUnavailable: return .filesystemIDUnavailable
        }
    }
}
