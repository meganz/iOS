import MEGAAppSDKRepo
import MEGASdk
import XCTest

final class BackupSubstateMappingTests: XCTestCase {
    
    func testBackupSubstateEntity_OnUpdateType_shouldReturnCorrectMapping() {
        let sut: [BackUpSubState] = [.invalid, .noSyncError, .unknownError, .unsupportedFileSystem, .invalidRemoteType, .invalidLocalType, .initialScanFailed, .localPathTemporaryUnavailable, .localPathUnavailable, .remoteNodeNotFound, .storageOverquota, .accountExpired, .foreignTargetOverstorage, .remotePathHasChanged, .shareNonFullAccess, .localFilesystemMismatch, .putNodesError, .activeSyncBelowPath, .activeSyncAbovePath, .remoteNodeMovedToRubbish, .remoteNodeInsideRubbish, .vBoxSharedFolderUnsupported, .localPathSyncCollision, .accountBlocked, .unknownTemporaryError, .tooManyActionPackets, .loggedOut, .wholeAccountRefetched, .missingParentNode, .backupModified, .backupSourceNotBelowDrive, .syncConfigWriteFailure, .activeSyncSamePath, .couldNotMoveCloudNodes, .couldNotCreateIgnoreFile, .syncConfigReadFailure, .unknownDrivePath, .invalidScanInterval, .notificationSystemUnavailable, .unableToAddWatch, .unableToRetrieveRootFSID, .unableToOpenDatabase, .insufficientDiskSpace, .failureAccessingPersistentStorage, .mismatchOfRootRSID, .filesystemFileIdsAreUnstable, .filesystemIDUnavailable]
        
        for type in sut {
            switch type {
            case .invalid: XCTAssertEqual(type.toBackupSubstateEntity(), .invalid)
            case .noSyncError: XCTAssertEqual(type.toBackupSubstateEntity(), .noSyncError)
            case .unknownError: XCTAssertEqual(type.toBackupSubstateEntity(), .unknownError)
            case .unsupportedFileSystem: XCTAssertEqual(type.toBackupSubstateEntity(), .unsupportedFileSystem)
            case .invalidRemoteType: XCTAssertEqual(type.toBackupSubstateEntity(), .invalidRemoteType)
            case .invalidLocalType: XCTAssertEqual(type.toBackupSubstateEntity(), .invalidLocalType)
            case .initialScanFailed: XCTAssertEqual(type.toBackupSubstateEntity(), .initialScanFailed)
            case .localPathTemporaryUnavailable: XCTAssertEqual(type.toBackupSubstateEntity(), .localPathTemporaryUnavailable)
            case .localPathUnavailable: XCTAssertEqual(type.toBackupSubstateEntity(), .localPathUnavailable)
            case .remoteNodeNotFound: XCTAssertEqual(type.toBackupSubstateEntity(), .remoteNodeNotFound)
            case .storageOverquota: XCTAssertEqual(type.toBackupSubstateEntity(), .storageOverquota)
            case .accountExpired: XCTAssertEqual(type.toBackupSubstateEntity(), .accountExpired)
            case .foreignTargetOverstorage: XCTAssertEqual(type.toBackupSubstateEntity(), .foreignTargetOverstorage)
            case .remotePathHasChanged: XCTAssertEqual(type.toBackupSubstateEntity(), .remotePathHasChanged)
            case .shareNonFullAccess: XCTAssertEqual(type.toBackupSubstateEntity(), .shareNonFullAccess)
            case .localFilesystemMismatch: XCTAssertEqual(type.toBackupSubstateEntity(), .localFilesystemMismatch)
            case .putNodesError: XCTAssertEqual(type.toBackupSubstateEntity(), .putNodesError)
            case .activeSyncBelowPath: XCTAssertEqual(type.toBackupSubstateEntity(), .activeSyncBelowPath)
            case .activeSyncAbovePath: XCTAssertEqual(type.toBackupSubstateEntity(), .activeSyncAbovePath)
            case .remoteNodeMovedToRubbish: XCTAssertEqual(type.toBackupSubstateEntity(), .remoteNodeMovedToRubbish)
            case .remoteNodeInsideRubbish: XCTAssertEqual(type.toBackupSubstateEntity(), .remoteNodeInsideRubbish)
            case .vBoxSharedFolderUnsupported: XCTAssertEqual(type.toBackupSubstateEntity(), .vBoxSharedFolderUnsupported)
            case .localPathSyncCollision: XCTAssertEqual(type.toBackupSubstateEntity(), .localPathSyncCollision)
            case .accountBlocked: XCTAssertEqual(type.toBackupSubstateEntity(), .accountBlocked)
            case .unknownTemporaryError: XCTAssertEqual(type.toBackupSubstateEntity(), .unknownTemporaryError)
            case .tooManyActionPackets: XCTAssertEqual(type.toBackupSubstateEntity(), .tooManyActionPackets)
            case .loggedOut: XCTAssertEqual(type.toBackupSubstateEntity(), .loggedOut)
            case .wholeAccountRefetched: XCTAssertEqual(type.toBackupSubstateEntity(), .wholeAccountRefetched)
            case .missingParentNode: XCTAssertEqual(type.toBackupSubstateEntity(), .missingParentNode)
            case .backupModified: XCTAssertEqual(type.toBackupSubstateEntity(), .backupModified)
            case .backupSourceNotBelowDrive: XCTAssertEqual(type.toBackupSubstateEntity(), .backupSourceNotBelowDrive)
            case .syncConfigWriteFailure: XCTAssertEqual(type.toBackupSubstateEntity(), .syncConfigWriteFailure)
            case .activeSyncSamePath: XCTAssertEqual(type.toBackupSubstateEntity(), .activeSyncSamePath)
            case .couldNotMoveCloudNodes: XCTAssertEqual(type.toBackupSubstateEntity(), .couldNotMoveCloudNodes)
            case .couldNotCreateIgnoreFile: XCTAssertEqual(type.toBackupSubstateEntity(), .couldNotCreateIgnoreFile)
            case .syncConfigReadFailure: XCTAssertEqual(type.toBackupSubstateEntity(), .syncConfigReadFailure)
            case .unknownDrivePath: XCTAssertEqual(type.toBackupSubstateEntity(), .unknownDrivePath)
            case .invalidScanInterval: XCTAssertEqual(type.toBackupSubstateEntity(), .invalidScanInterval)
            case .notificationSystemUnavailable: XCTAssertEqual(type.toBackupSubstateEntity(), .notificationSystemUnavailable)
            case .unableToAddWatch: XCTAssertEqual(type.toBackupSubstateEntity(), .unableToAddWatch)
            case .unableToRetrieveRootFSID: XCTAssertEqual(type.toBackupSubstateEntity(), .unableToRetrieveRootFSID)
            case .unableToOpenDatabase: XCTAssertEqual(type.toBackupSubstateEntity(), .unableToOpenDatabase)
            case .insufficientDiskSpace: XCTAssertEqual(type.toBackupSubstateEntity(), .insufficientDiskSpace)
            case .failureAccessingPersistentStorage: XCTAssertEqual(type.toBackupSubstateEntity(), .failureAccessingPersistentStorage)
            case .mismatchOfRootRSID: XCTAssertEqual(type.toBackupSubstateEntity(), .mismatchOfRootRSID)
            case .filesystemFileIdsAreUnstable: XCTAssertEqual(type.toBackupSubstateEntity(), .filesystemFileIdsAreUnstable)
            case .filesystemIDUnavailable: XCTAssertEqual(type.toBackupSubstateEntity(), .filesystemIDUnavailable)
            default: break
            }
        }
    }
}
