import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPhotos
import MEGAPreference
import MEGASwift
import SwiftUI
import UIKit
import Video

@MainActor
struct MediaTabViewControllerFactory {
    private let navigationController: UINavigationController
    private let tabViewModels: [MediaTab: any MediaTabContentViewModel]?
    private let monitorCameraUploadUseCase: (any MonitorCameraUploadUseCaseProtocol)?
    private let devicePermissionHandler: (any DevicePermissionsHandling)?
    private let cameraUploadsSettingsViewRouter: (any Routing)?
    private let cameraUploadProgressRouter: (any CameraUploadProgressRouting)?

    init(
        navigationController: UINavigationController,
        tabViewModels: [MediaTab: any MediaTabContentViewModel]? = nil,
        monitorCameraUploadUseCase: (any MonitorCameraUploadUseCaseProtocol)? = nil,
        devicePermissionHandler: (any DevicePermissionsHandling)? = nil,
        cameraUploadsSettingsViewRouter: (any Routing)? = nil,
        cameraUploadProgressRouter: (any CameraUploadProgressRouting)? = nil
    ) {
        self.navigationController = navigationController
        self.tabViewModels = tabViewModels
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.devicePermissionHandler = devicePermissionHandler
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.cameraUploadProgressRouter = cameraUploadProgressRouter
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
            title: Strings.Localizable.Photos.SearchResults.Media.Section.title,
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
        let cameraUploadsSettingsViewRouter = self.cameraUploadsSettingsViewRouter ?? CameraUploadsSettingsViewRouter(presenter: navigationController) {}
        let cameraUploadProgressRouter = self.cameraUploadProgressRouter ?? CameraUploadProgressRouter(presenter: navigationController)
        
        return MediaTabViewModel(
            tabViewModels: tabViewModels,
            visualMediaSearchResultsViewModel: VisualMediaSearchFactory.makeVisualMediaSearchResultsViewModel(
                presenter: navigationController),
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            cameraUploadProgressRouter: cameraUploadProgressRouter
        )
    }

    private static func makeDefaultTabViewModels(navigationController: UINavigationController) -> [MediaTab: any MediaTabContentViewModel] {
        let syncModel = VideoRevampSyncModel()
        let videoSelection = VideoSelection()

        let videoTabViewModel = MediaTabVideoFactory.makeVideoTabViewModel(
            syncModel: syncModel,
            videoSelection: videoSelection,
            navigationController: navigationController
        )

        let playlistTabViewModel = MediaTabPlaylistFactory.makePlaylistTabViewModel(
            syncModel: syncModel,
            navigationController: navigationController,
            hiddenNodesFeatureFlagEnabled: DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
        )

        return [
            .timeline: MediaTabTimelineFactory.makeMediaTimelineTabContentViewModel(navigationController: navigationController),
            .album: MediaTabAlbumFactory.makeMediaAlbumTabContentViewModel(navigationController: navigationController),
            .video: videoTabViewModel,
            .playlist: playlistTabViewModel
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
