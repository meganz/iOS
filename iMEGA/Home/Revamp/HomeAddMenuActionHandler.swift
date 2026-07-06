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

    private let permissionHandler: any DevicePermissionsHandling

    private let permissionRouter: PermissionAlertRouter

    var openLinkRouter: OpenLinkRouter?

    init(
        fileUploadingRouter: FileUploadingRouter,
        tracker: any AnalyticsTracking,
        newChatRouter: NewChatRouter,
        navigationController: UINavigationController,
        permissionHandler: some DevicePermissionsHandling,
        permissionRouter: PermissionAlertRouter
    ) {
        self.tracker = tracker
        self.newChatRouter = newChatRouter
        self.navigationController = navigationController
        self.fileUploadingRouter = fileUploadingRouter
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
        case .openLink:
            trackOpenLinkEvent()
            openLinkRouter?.start()
        case .newChat:
            newChatRouter.presentNewChat(from: navigationController)
        }
    }

    private func uploadFromPhotos() {
        fileUploadingRouter.upload(from: .albumNew)
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

    private func trackOpenLinkEvent() {
        tracker.trackAnalyticsEvent(with: OpenLinkMenuItemEvent())
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
