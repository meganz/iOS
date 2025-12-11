import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPermissions
import MEGAPreference
import SwiftUI
import UIKit
import Video

@MainActor
struct MediaTabViewControllerFactory {
    private let navigationController: UINavigationController
    private let tabViewModels: [MediaTab: any MediaTabInteractiveProvider]?
    private let monitorCameraUploadUseCase: (any MonitorCameraUploadUseCaseProtocol)?
    private let devicePermissionHandler: (any DevicePermissionsHandling)?

    init(
        navigationController: UINavigationController,
        tabViewModels: [MediaTab: any MediaTabInteractiveProvider]? = nil,
        monitorCameraUploadUseCase: (any MonitorCameraUploadUseCaseProtocol)? = nil,
        devicePermissionHandler: (any DevicePermissionsHandling)? = nil
    ) {
        self.navigationController = navigationController
        self.tabViewModels = tabViewModels
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.devicePermissionHandler = devicePermissionHandler
    }

    static func make(nc: UINavigationController? = nil) -> MediaTabViewControllerFactory {
        let navigationController = nc ?? MEGANavigationController()

        return MediaTabViewControllerFactory(
            navigationController: navigationController,
            tabViewModels: makeDefaultTabViewModels(navigationController: navigationController),
            monitorCameraUploadUseCase: makeDefaultMonitorCameraUploadUseCase(),
            devicePermissionHandler: makeDefaultDevicePermissionHandler()
        )
    }

    // MARK: - Build Methods
    func build() -> UIViewController {
        let viewModel = makeMediaTabViewModel()
        let toolbarItemsFactory = makeToolbarItemsFactory()
        let hostingController = MediaTabHostingController(
            viewModel: viewModel,
            toolbarItemsFactory: toolbarItemsFactory
        )

        hostingController.tabBarItem = UITabBarItem(
            title: "Media", // WIP: Replace with localized string
            image: MEGAAssets.UIImage.cameraUploadsIcon,
            selectedImage: nil
        )

        navigationController.viewControllers = [hostingController]

        return navigationController
    }

    func buildBare() -> UIViewController {
        let viewModel = makeMediaTabViewModel()
        let toolbarItemsFactory = makeToolbarItemsFactory()
        let hostingController = MediaTabHostingController(
            viewModel: viewModel,
            toolbarItemsFactory: toolbarItemsFactory
        )

        return hostingController
    }

    // MARK: - Private Methods

    private func makeMediaTabViewModel() -> MediaTabViewModel {
        let tabViewModels = self.tabViewModels ?? Self.makeDefaultTabViewModels(navigationController: navigationController)
        let monitorCameraUploadUseCase = self.monitorCameraUploadUseCase ?? Self.makeDefaultMonitorCameraUploadUseCase()
        let devicePermissionHandler = self.devicePermissionHandler ?? Self.makeDefaultDevicePermissionHandler()

        return MediaTabViewModel(
            tabViewModels: tabViewModels,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler
        )
    }

    private static func makeDefaultTabViewModels(navigationController: UINavigationController) -> [MediaTab: any MediaTabInteractiveProvider] {
        let syncModel = VideoRevampSyncModel()
        let videoSelection = VideoSelection()

        let videoTabViewModel = MediaTabVideoFactory.makeVideoTabViewModel(
            syncModel: syncModel,
            videoSelection: videoSelection,
            navigationController: navigationController
        )

        // WIP: Replace other mock ViewModels when ready
        return [
            .timeline: MockTimelineViewModel(),
            .album: MockAlbumViewModel(),
            .video: videoTabViewModel,
            .playlist: MockPlaylistViewModel()
        ]
    }

    private static func makeDefaultMonitorCameraUploadUseCase() -> any MonitorCameraUploadUseCaseProtocol {
        MonitorCameraUploadUseCase(
            cameraUploadRepository: CameraUploadsStatsRepository.newRepo,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            preferenceUseCase: PreferenceUseCase.default
        )
    }

    private static func makeDefaultDevicePermissionHandler() -> any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }

    private func makeToolbarItemsFactory() -> MediaBottomToolbarItemsFactory {
        return MediaBottomToolbarItemsFactory(
            actionDelegate: nil // Will be set by MediaTabHostingController
        )
    }
}
