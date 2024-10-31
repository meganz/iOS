import DeviceCenter
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI

extension MyAccountHallViewModel {
    func makeDeviceCenterBridge() {
        deviceCenterBridge.cameraUploadActionTapped = { [weak self] cameraUploadStatusChanged in
            self?.router.didTapCameraUploadsAction(statusChanged: cameraUploadStatusChanged)
        }
        
        deviceCenterBridge.renameActionTapped = { [weak self] renameEntity in
            self?.router.didTapRenameAction(renameEntity)
        }
        
        deviceCenterBridge.infoActionTapped = { [weak self] resourceInfoModel in
            self?.router.didTapInfoAction(resourceInfoModel)
        }
        
        deviceCenterBridge.showInTapped = { [weak self] showInActionEntity in
            self?.router.didTapNavigateToContent(showInActionEntity)
        }
    }
    
    func makeDeviceCenterAssetData() -> DeviceCenterAssets {
        DeviceCenterAssets(
            deviceListAssets:
                makeDeviceListAssets(),
            backupListAssets:
                makeBackupListAssets(),
            emptyStateAssets:
                makeEmptyStateAssets(),
            searchAssets:
                makeSearchAssets(),
            deviceCenterActions: deviceCenterActionList(),
            deviceIconNames: deviceIconNamesList()
        )
    }
    
    private func makeDeviceListAssets() -> DeviceListAssets {
        return DeviceListAssets(
            title: Strings.Localizable.Device.Center.title,
            currentDeviceTitle: Strings.Localizable.Device.Center.Current.Device.title,
            otherDevicesTitle: Strings.Localizable.Device.Center.Other.Devices.title,
            deviceDefaultName: Strings.Localizable.Device.Center.Default.Device.title
        )
    }
    
    private func makeBackupListAssets() -> BackupListAssets {
        return BackupListAssets(
            backupTypes: [
                BackupType(type: .backupUpload, iconName: BackUpTypeIconAssets.backupFolder),
                BackupType(type: .cameraUpload, iconName: BackUpTypeIconAssets.cameraUploadsFolder),
                BackupType(type: .mediaUpload, iconName: BackUpTypeIconAssets.cameraUploadsFolder),
                BackupType(type: .twoWay, iconName: BackUpTypeIconAssets.syncFolder),
                BackupType(type: .downSync, iconName: BackUpTypeIconAssets.syncFolder),
                BackupType(type: .upSync, iconName: BackUpTypeIconAssets.syncFolder),
                BackupType(type: .invalid, iconName: BackUpTypeIconAssets.syncFolder)
            ]
        )
    }
    
    private func makeEmptyStateAssets() -> EmptyStateAssets {
        return EmptyStateAssets(
            image: EmptyStateIconAssets.searchEmptyState,
            title: Strings.Localizable.noResults
        )
    }
    
    private func makeSearchAssets() -> SearchAssets {
        return SearchAssets(
            placeHolder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel,
            backgroundColor: TokenColors.Background.surface1.swiftUI
        )
    }
    
    private func deviceCenterActionList() -> [ContextAction] {
        return [
            ContextAction(
                type: .cameraUploads,
                title: Strings.Localizable.General.cameraUploads,
                dynamicSubtitle: {
                    CameraUploadManager.isCameraUploadEnabled ? Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.enabled :
                        Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.disabled
                },
                icon: DeviceCenterActionIconAssets.cameraUploadsSettings
            ),
            ContextAction(
                type: .info,
                title: Strings.Localizable.info,
                icon: DeviceCenterActionIconAssets.info
            ),
            ContextAction(
                type: .rename,
                title: Strings.Localizable.rename,
                icon: DeviceCenterActionIconAssets.rename
            ),
            ContextAction(
                type: .sort,
                title: Strings.Localizable.sortTitle,
                icon: DeviceCenterActionIconAssets.sort,
                subActions: [
                    ContextAction(
                        type: .sortAscending,
                        title: Strings.Localizable.nameAscending,
                        icon: DeviceCenterActionIconAssets.ascending
                    ),
                    ContextAction(
                        type: .sortDescending,
                        title: Strings.Localizable.nameDescending,
                        icon: DeviceCenterActionIconAssets.descending
                    ),
                    ContextAction(
                        type: .sortLargest,
                        title: Strings.Localizable.largest,
                        icon: DeviceCenterActionIconAssets.largest
                    ),
                    ContextAction(
                        type: .sortSmallest,
                        title: Strings.Localizable.smallest,
                        icon: DeviceCenterActionIconAssets.smallest
                    ),
                    ContextAction(
                        type: .sortNewest,
                        title: Strings.Localizable.newest,
                        icon: DeviceCenterActionIconAssets.newest
                    ),
                    ContextAction(
                        type: .sortOldest,
                        title: Strings.Localizable.oldest,
                        icon: DeviceCenterActionIconAssets.oldest
                    ),
                    ContextAction(
                        type: .sortLabel,
                        title: Strings.Localizable.CloudDrive.Sort.label,
                        icon: DeviceCenterActionIconAssets.label
                    ),
                    ContextAction(
                        type: .sortFavourite,
                        title: Strings.Localizable.favourite,
                        icon: DeviceCenterActionIconAssets.favourite
                    )
                ]
            )
        ]
    }
    
    private func deviceIconNamesList() -> [BackupDeviceTypeEntity: String] {
        [
            .android: DeviceIconAssets.android,
            .iphone: DeviceIconAssets.ios,
            .linux: DeviceIconAssets.pcLinux,
            .mac: DeviceIconAssets.pcMac,
            .win: DeviceIconAssets.pcWindows,
            .defaultMobile: DeviceIconAssets.mobile,
            .defaultPc: DeviceIconAssets.pc
        ]
    }
    
    private struct DeviceIconAssets {
        static let android = "android"
        static let ios = "ios"
        static let pcLinux = "pc-linux"
        static let pcMac = "pc-mac"
        static let pcWindows = "pc-windows"
        static let mobile = "mobile"
        static let pc = "pc"
    }
    
    private struct DeviceCenterActionIconAssets {
        static let cameraUploadsSettings = "cameraUploadsSettings"
        static let info = "info"
        static let rename = "rename"
        static let cloudDriveFolder = "cloudDriveFolder"
        static let sort = "sort"
        static let ascending = "ascending"
        static let descending = "descending"
        static let largest = "largest"
        static let smallest = "smallest"
        static let newest = "newest"
        static let oldest = "oldest"
        static let label = "label"
        static let favourite = "favourite"
    }
    
    private struct BackUpStatusIconAssets {
        static let upToDate = "backUpStatusUpToDate"
        static let updating = "backUpStatusUpdating"
        static let noCameraUploads = "backUpStatusNoCameraUploads"
        static let disabled  = "backUpStatusDisabled"
        static let offlineStatus = "backUpStatusOfflineStatus"
        static let error = "backUpStatusError"
        static let paused = "backUpStatusPaused"
        static let outOfQuota = "backUpStatusOutOfQuota"
    }
    
    private struct BackUpTypeIconAssets {
        static let backupFolder = "backupFolder"
        static let cameraUploadsFolder = "cameraUploadsFolder"
        static let syncFolder = "syncFolder"
    }
    
    private struct EmptyStateIconAssets {
        static let searchEmptyState = "searchEmptyState"
    }
}
