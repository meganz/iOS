import DeviceCenter
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
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
    
    func makeDeviceCenterActionList() -> [ContextAction] {
        [
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
}
