import Combine
import ContentLibraries
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

struct PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    private let contentMode: PhotoLibraryContentMode
    private let tracker: any AnalyticsTracking
    
    /// Present only where the library paginates, injected by the same composition root that reads
    /// the flag. Without it a paginated handover still opens, on its run alone.
    private let mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)?
    
    init(contentMode: PhotoLibraryContentMode = .library,
         tracker: some AnalyticsTracking = DIContainer.tracker,
         mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)? = nil) {
        self.contentMode = contentMode
        self.tracker = tracker
        self.mediaTimelineUseCase = mediaTimelineUseCase
    }
    
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard {
        PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photoByYear: photoByYear,
                thumbnailLoader: makeThumbnailLoader(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase()
            )
        )
    }
    
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard {
        PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photoByMonth: photoByMonth,
                thumbnailLoader: makeThumbnailLoader(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase()
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailLoader: makeThumbnailLoader(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase()
            )
        )
    }
    
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity]) {
        present {
            MEGAPhotoBrowserViewController.photoBrowser(
                currentPhoto: photo,
                allPhotos: allPhotos,
                displayMode: contentMode.displayMode,
                isFromSharedItem: contentMode == .mediaDiscoverySharedItems)
        }
    }
    
    func openPhotoBrowser(for photo: NodeEntity, in context: PhotoBrowserPaginationContext) {
        guard let mediaTimelineUseCase else {
            // The library paginates and this router cannot: opening on the run alone is the same
            // browser the non-paginated entry points get, only shorter.
            openPhotoBrowser(for: photo, allPhotos: context.nodes)
            return
        }
        present {
            MEGAPhotoBrowserViewController.photoBrowser(
                currentPhoto: photo,
                context: context,
                mediaTimelineUseCase: mediaTimelineUseCase,
                displayMode: contentMode.displayMode)
        }
    }
    
    private func present(_ makeBrowser: () -> MEGAPhotoBrowserViewController) {
        tracker.trackAnalyticsEvent(with: DIContainer.singlePhotoSelectedEvent)

        guard let topController = topViewController() else { return }

        if topController.definesPresentationContext == false && topController.children.isEmpty { return }

        topController.modalPresentationStyle = .popover
        topController.present(makeBrowser(), animated: true)
    }
    
    func openCameraUploadSettings(viewModel: PhotoLibraryModeAllViewModel) {
        CameraUploadsSettingsViewRouter(
            presenter: UIApplication.mnz_visibleViewController().navigationController,
            closure: { viewModel.invalidateCameraUploadEnabledSetting() })
        .start()
    }
    
    func showTakenDownNodeAlert() {
        guard let topController = topViewController() else { return }
        let alert = UIAlertController(model: AlertModelFactory.makeTakenDownModel())
        topController.present(alert, animated: true)
    }
    
    private func makeThumbnailLoader() -> any ThumbnailLoaderProtocol {
        ThumbnailLoaderFactory.makeThumbnailLoader(mode: contentMode)
    }
    
    private func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
    }
    
    private func topViewController() -> UIViewController? {
        guard var topController = UIApplication.mnz_keyWindow()?.rootViewController else { return nil }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}

extension PhotoLibraryContentMode {
    var displayMode: DisplayMode {
        switch self {
        case .library:
            .photosTimeline
        case .album, .albumPicker:
            .photosAlbum
        case .mediaDiscovery, .mediaDiscoverySharedItems:
            .cloudDrive
        case .albumLink:
            .albumLink
        case .mediaDiscoveryFolderLink:
            .nodeInsideFolderLink
        case .recentBucket:
            .recents
        }
    }
}
