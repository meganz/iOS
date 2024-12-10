import Combine
import MEGADomain
import MEGAL10n
import MEGAUI
import SwiftUI

@MainActor
public class DeviceCenterItemViewModel: ObservableObject, Identifiable {
    private let router: (any DeviceListRouting)?
    private let refreshDevicesPublisher: PassthroughSubject<Void, Never>?
    private let deviceCenterUseCase: DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let deviceCenterBridge: DeviceCenterBridge
    private let isCameraUploadsAvailable: Bool
    private let currentDeviceUUID: String
    private var itemType: DeviceCenterItemType
    var assets: ItemAssets
    var availableActions: [ContextAction] = []
    var statusSubtitle: String?
    var isBackup: Bool = false
    var hasErrorStatus: Bool = false
    var sortedAvailableActions: [ContextAction.Category: [ContextAction]]
    var updateSelectedViewModel: ((DeviceCenterItemViewModel?) -> Void)?
    
    @Published var shouldShowBackupPercentage: Bool = false
    @Published var backupPercentage: String = ""
    
    var mainActionIconName: String {
       switch itemType {
       case .backup: "info"
       case .device: "moreList"
       default: ""
       }
    }
    
    var name: String {
       switch itemType {
       case .backup(let backup): backup.name
       case .device(let device): device.name.isNotEmpty ? device.name : assets.defaultName ?? ""
       case .unknown: ""
       }
    }
    
    /// `router` and `refreshDevicesPublisher` are declared as optional with a nil default value to accommodate the shared usage of `DeviceCenterItemViewModel` across different item types (devices, backups, sync, and camera upload (CU) folders). These properties are essential for navigating and refreshing the UI when interacting with device-related functionalities. However, for other item types like backups, sync, and CU folders, these functionalities are not required.
    init(
        router: (any DeviceListRouting)? = nil,
        refreshDevicesPublisher: PassthroughSubject<Void, Never>? = nil,
        deviceCenterUseCase: DeviceCenterUseCaseProtocol,
        nodeUseCase: any NodeUseCaseProtocol,
        deviceCenterBridge: DeviceCenterBridge,
        itemType: DeviceCenterItemType,
        sortedAvailableActions: [ContextAction.Category: [ContextAction]],
        isCUActionAvailable: Bool,
        assets: ItemAssets,
        currentDeviceUUID: () -> String
    ) {
        self.router = router
        self.refreshDevicesPublisher = refreshDevicesPublisher
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.deviceCenterBridge = deviceCenterBridge
        self.itemType = itemType
        self.sortedAvailableActions = sortedAvailableActions
        self.isCameraUploadsAvailable = isCUActionAvailable
        self.assets = assets
        self.currentDeviceUUID = currentDeviceUUID()
        
        self.configure()
    }
    
    private func configure() {
        if case .backup = itemType {
            statusSubtitle = backupStatusDetailedErrorMessage()
            hasErrorStatus = statusSubtitle != nil
            isBackup = true
        }
        
        calculateProgress()
    }
    
    private func calculateProgress() {
        if assets.backupStatus.status == .updating {
            var progress = 0
            switch itemType {
            case .backup(let backup):
                progress = Int(backup.progress)
                
            case .device(let device):
                progress = device.backups?.first(where: {
                    $0.backupStatus == .updating
                }).flatMap {
                    Int($0.progress)
                } ?? 0
            default: break
            }
            progress = min(progress, 100)
            
            backupPercentage = "\(progress) %"
            shouldShowBackupPercentage = progress > 0
        }
    }
    
    private func actionsFor(device: DeviceEntity) -> [ContextAction.Category] {
        if device.isNewDeviceWithoutCU(currentUUID: currentDeviceUUID) {
            return [.cameraUploads]
        } else if isCameraUploadsAvailable {
            return  [.info, .cameraUploads, .rename]
        }
        return [.info, .rename]
    }
    
    private func handleRenameCompletion() {
        refreshDevicesPublisher?.send()
    }
    
    private func makeRenameEntity(_ device: DeviceEntity) async -> RenameActionEntity {
        let deviceNames = await deviceCenterUseCase.fetchDeviceNames()
        
        return RenameActionEntity(
            oldName: device.name,
            otherNamesInContext: deviceNames,
            actionType: .device(
                deviceId: device.id,
                maxCharacters: 32
            ),
            alertTitles: [
                .invalidCharacters: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay),
                .duplicatedName: Strings.Localizable.Device.Center.Rename.Device.Duplicated.name,
                .nameTooLong: Strings.Localizable.Device.Center.Rename.Device.Invalid.Long.name,
                .none: Strings.Localizable.rename
            ],
            alertMessage: [
                .duplicatedName: Strings.Localizable.Device.Center.Rename.Device.Different.name,
                .none: Strings.Localizable.renameNodeMessage
            ],
            alertPlaceholder: Strings.Localizable.Device.Center.Rename.Device.title) { [weak self] in
                Task {
                    await self?.handleRenameCompletion()
                }
            }
    }

    private func makeNodeInfoEntity(for backup: BackupEntity) async -> ResourceInfoModel {
        let folderInfo = await FolderInfoFactory(nodeUseCase: nodeUseCase).info(from: backup)
        
        return ResourceInfoModel(
            icon: assets.iconName,
            name: backup.name,
            counter: ResourceCounter(
                files: folderInfo.files,
                folders: folderInfo.folders
            ),
            totalSize: folderInfo.totalSize,
            added: folderInfo.added)
    }

    private func makeDeviceInfoEntity(_ device: DeviceEntity) async -> ResourceInfoModel {
        guard let backups = device.backups else {
            return ResourceInfoModel(
                icon: assets.iconName,
                name: device.name,
                counter: ResourceCounter.emptyCounter
            )
        }
        
        let folderInfo = await FolderInfoFactory(nodeUseCase: nodeUseCase).info(from: backups)

        return ResourceInfoModel(
            icon: assets.iconName,
            name: device.name,
            counter: ResourceCounter(
                files: folderInfo.files,
                folders: folderInfo.folders
            ),
            totalSize: folderInfo.totalSize
        )
    }

    private func handleBackupInfoAction() async {
        guard case let .backup(backupEntity) = itemType else { return }
        let infoEntity = await makeNodeInfoEntity(for: backupEntity)
        deviceCenterBridge.infoActionTapped(infoEntity)
    }
    
    private func handleDeviceAction(_ type: ContextAction.Category, device: DeviceEntity) async {
        switch type {
        case .cameraUploads:
            handleCameraUploadAction()
        case .rename:
            await handleRenameDeviceAction(device)
        case .info:
            let infoEntity = await makeDeviceInfoEntity(device)
            deviceCenterBridge.infoActionTapped(infoEntity)
        default: break
        }
    }
    
    private func handleCameraUploadAction() {
        deviceCenterBridge.cameraUploadActionTapped { [weak self] in
            Task {
                guard let self else { return }
                self.refreshDevicesPublisher?.send()
            }
        }
    }
    
    private func handleRenameDeviceAction(_ device: DeviceEntity) async {
        let renameEntity = await makeRenameEntity(device)
        deviceCenterBridge.renameActionTapped(renameEntity)
    }
    
    private func availableActionsFor(device: DeviceEntity) -> [ContextAction] {
        actionsFor(device: device)
            .sortedMapping(sortedActions: sortedAvailableActions)
    }
    
    func nodeForItemType() -> NodeEntity? {
        switch itemType {
        case .backup(let backupEntity):
            return nodeUseCase.nodeForHandle(backupEntity.rootHandle)
        case .device(let deviceEntity):
            guard let backupNode = deviceEntity.backups?.first else { return nil }
            return nodeUseCase.nodeForHandle(backupNode.rootHandle)
        default: return nil
        }
    }
    
    func handleMainActionButtonPressed() {
        executeMainAction()
        if !isBackup {
            updateSelectedViewModel?(self)
        }
    }
    
    func executeMainAction() {
        switch itemType {
        case .backup:
            Task { [weak self] in
                await self?.handleBackupInfoAction()
            }
        case .device(let device):
            availableActions = availableActionsFor(device: device)
        default: break
        }
    }
    
    func showDetail() {
        switch itemType {
        case .backup(let backup):
            guard let nodeEntity = self.nodeForItemType() else { return }
            let statusErrorMessage = backupStatusDetailedErrorMessage()
            
            switch backup.type {
            case .cameraUpload, .mediaUpload, .twoWay:
                deviceCenterBridge.showInTapped(
                    NavigateToContentActionEntity(
                        type: .showInCloudDrive,
                        node: nodeEntity,
                        error: statusErrorMessage
                    )
                )
            default:
                deviceCenterBridge.showInTapped(
                    NavigateToContentActionEntity(
                        type: .showInBackups,
                        node: nodeEntity,
                        error: statusErrorMessage
                    )
                )
            }
        case .device(let device):
            guard let router else { return }
            if device.isNewDeviceWithoutCU(currentUUID: currentDeviceUUID) {
                router.showCurrentDeviceEmptyState(
                    currentDeviceUUID,
                    deviceName: UIDevice.current.modelName,
                    deviceIcon: assets.iconName
                )
            } else {
                let currentDeviceId = deviceCenterUseCase.loadCurrentDeviceId()
                router.showDeviceBackups(
                    device,
                    deviceIcon: assets.iconName,
                    isCurrentDevice: device.id == currentDeviceUUID || (device.id == currentDeviceId)
                )
            }
        default: break
        }
    }
    
    func executeAction(_ type: ContextAction.Category) async {
        if case .device(let device) = itemType {
            await handleDeviceAction(type, device: device)
        }
    }
    
    func backupStatusDetailedErrorMessage() -> String? {
        guard case let .backup(backup) = itemType,
              backup.backupStatus == .error else { return nil }
        switch backup.substate {
        case .unknownError: return Strings.Localizable.Device.Center.Backup.Error.unknown
        case .unsupportedFileSystem: return Strings.Localizable.Device.Center.Backup.Error.fileSystemUnsupported
        case .invalidRemoteType: return Strings.Localizable.Device.Center.Backup.Error.folderCantSync
        case .invalidLocalType: return Strings.Localizable.Device.Center.Backup.Error.fileSyncIndividual
        case .initialScanFailed: return Strings.Localizable.Device.Center.Backup.Error.initialScanFailed
        case .localPathTemporaryUnavailable: return Strings.Localizable.Device.Center.Backup.Error.folderDeviceUnlocatedNow
        case .localPathUnavailable: return Strings.Localizable.Device.Center.Backup.Error.folderDeviceUnlocated
        case .remoteNodeNotFound: return Strings.Localizable.Device.Center.Backup.Error.folderMegaMovedOrDeleted
        case .storageOverquota: return Strings.Localizable.Device.Center.Backup.Error.storageQuotaReached
        case .accountExpired: return Strings.Localizable.Device.Center.Backup.Error.planExpired
        case .foreignTargetOverstorage: return Strings.Localizable.Device.Center.Backup.Error.userSharedQuotaReached
        case .remotePathHasChanged: return Strings.Localizable.Device.Center.Backup.Error.folderMegaMovedOrDeleted
        case .shareNonFullAccess: return Strings.Localizable.Device.Center.Backup.Error.sharedFolderNoFullAccess
        case .localFilesystemMismatch: return Strings.Localizable.Device.Center.Backup.Error.filesInFolder
        case .putNodesError: return Strings.Localizable.Device.Center.Backup.Error.filesInFolder
        case .activeSyncBelowPath: return Strings.Localizable.Device.Center.Backup.Error.containsSyncedFolders
        case .activeSyncAbovePath: return Strings.Localizable.Device.Center.Backup.Error.insideSyncedFolder
        case .remoteNodeMovedToRubbish: return Strings.Localizable.Device.Center.Backup.Error.folderInRubbish
        case .remoteNodeInsideRubbish: return Strings.Localizable.Device.Center.Backup.Error.folderInRubbish
        case .vBoxSharedFolderUnsupported: return Strings.Localizable.Device.Center.Backup.Error.virtualboxFolders
        case .localPathSyncCollision: return Strings.Localizable.Device.Center.Backup.Error.insideSyncedFolder
        case .accountBlocked: return Strings.Localizable.Device.Center.Backup.Error.accountBlocked
        case .unknownTemporaryError: return Strings.Localizable.Device.Center.Backup.Error.problemSyncingContactSupport
        case .tooManyActionPackets: return Strings.Localizable.Device.Center.Backup.Error.accountReloaded
        case .loggedOut: return Strings.Localizable.Device.Center.Backup.Error.loggedOut
        case .wholeAccountRefetched: return Strings.Localizable.Device.Center.Backup.Error.accountReloaded
        case .backupModified: return Strings.Localizable.Device.Center.Backup.Error.changesToMegaFolder
        case .backupSourceNotBelowDrive: return Strings.Localizable.Device.Center.Backup.Error.externalDriveUnlocated
        case .syncConfigWriteFailure: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .activeSyncSamePath: return Strings.Localizable.Device.Center.Backup.Error.alreadySyncedPath
        case .couldNotMoveCloudNodes: return Strings.Localizable.Device.Center.Backup.Error.renamingFailed
        case .couldNotCreateIgnoreFile: return Strings.Localizable.Device.Center.Backup.Error.syncIgnored
        case .syncConfigReadFailure: return Strings.Localizable.Device.Center.Backup.Error.couldntReadSyncConfig
        case .unknownDrivePath: return Strings.Localizable.Device.Center.Backup.Error.unknownDrivePath
        case .invalidScanInterval: return Strings.Localizable.Device.Center.Backup.Error.invalidScanInterval
        case .notificationSystemUnavailable: return Strings.Localizable.Device.Center.Backup.Error.communicateWithFolderLocation
        case .unableToAddWatch: return Strings.Localizable.Device.Center.Backup.Error.addFilesystemWatch
        case .unableToRetrieveRootFSID: return Strings.Localizable.Device.Center.Backup.Error.cantReadSyncLocation
        case .unableToOpenDatabase: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .insufficientDiskSpace: return Strings.Localizable.Device.Center.Backup.Error.insufficientDownloadSpace
        case .failureAccessingPersistentStorage: return Strings.Localizable.Device.Center.Backup.Error.cantReadSyncLocation
        case .mismatchOfRootRSID: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .filesystemFileIdsAreUnstable: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        case .filesystemIDUnavailable: return Strings.Localizable.Device.Center.Backup.Error.syncOrBackupSetupAgain
        default: return Strings.Localizable.Device.Center.Backup.Error.unknown
        }
    }
}
