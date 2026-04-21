import Home
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGAUI
import UIKit

@MainActor
final class HomeAddMenuActionHandler: HomeAddMenuActionHandling {
    private let fileUploadingRouter: FileUploadingRouter
    private let tracker: any AnalyticsTracking
    private let newChatRouter: NewChatRouter
    private unowned let navigationController: UINavigationController
    private let uploadPhotoAssetsUseCase: any UploadPhotoAssetsUseCaseProtocol

    private let permissionHandler: any DevicePermissionsHandling

    private let permissionRouter: PermissionAlertRouter

    init(
        fileUploadingRouter: FileUploadingRouter,
        tracker: any AnalyticsTracking,
        newChatRouter: NewChatRouter,
        navigationController: UINavigationController,
        uploadPhotoAssetsUseCase: some UploadPhotoAssetsUseCaseProtocol,
        permissionHandler: some DevicePermissionsHandling,
        permissionRouter: PermissionAlertRouter
    ) {
        self.tracker = tracker
        self.newChatRouter = newChatRouter
        self.navigationController = navigationController
        self.fileUploadingRouter = fileUploadingRouter
        self.uploadPhotoAssetsUseCase = uploadPhotoAssetsUseCase
        self.permissionHandler = permissionHandler
        self.permissionRouter = permissionRouter
    }

    func handleAction(_ action: HomeAddMenuAction) {
        switch action {
        case .chooseFromPhotos:
            trackChooseFromPhotosEvent()
            uploadFromPhotos()
        case .capture:

            uploadFromCamera()
        case .importFromFiles:
            trackImportFromFilesEvent()
            fileUploadingRouter.upload(from: .imports)
        case .scanDocument:
            scanDocument()
        case .newTextFile:
            trackNewTextFileEvent()
            fileUploadingRouter.upload(from: .textFile)
        case .newChat:
            newChatRouter.presentNewChat(from: navigationController)
        }
    }

    private func uploadFromPhotos() {
        if DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosManualUploadPhotos) {
            fileUploadingRouter.upload(from: .albumNew)
        } else {
            permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
                guard let self else { return }
                if granted {
                    let selectionHandler: (([PHAsset], MEGANode) -> Void) = { [weak self] assets, targetNode in
                        guard let self else { return }
                        self.uploadFiles(fromPhotoAssets: assets, to: targetNode)
                    }
                    self.fileUploadingRouter.upload(from: .album(selectionHandler))
                } else {
                    permissionRouter.alertPhotosPermission()
                }
            }
        }
    }

    private func uploadFromCamera() {
        permissionHandler.requestVideoPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                fileUploadingRouter.upload(from: .camera)
            } else {
                permissionRouter.alertVideoPermission()
            }
        }
    }

    private func scanDocument() {
        permissionHandler.requestVideoPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                fileUploadingRouter.upload(from: .documentScan)
            } else {
                permissionRouter.alertVideoPermission()
            }
        }
    }

    private func uploadFiles(fromPhotoAssets assets: [PHAsset], to parentNode: MEGANode) {
        uploadPhotoAssetsUseCase.upload(photoIdentifiers: assets.map(\.localIdentifier), to: parentNode.handle)
    }

    private func trackChooseFromPhotosEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveChooseFromPhotosMenuToolbarEvent())
    }

    private func trackImportFromFilesEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveImportFromFilesMenuToolbarEvent())
    }

    private func trackNewTextFileEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveNewTextFileMenuToolbarEvent())
    }
}
