import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import SwiftUI

protocol PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity])
    func openCameraUploadSettings(viewModel: PhotoLibraryModeAllViewModel)
}

struct PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    private let contentMode: PhotoLibraryContentMode
    private let tracker: any AnalyticsTracking
    
    init(contentMode: PhotoLibraryContentMode = .library,
         tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.contentMode = contentMode
        self.tracker = tracker
    }
    
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard {
        return PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photoByYear: photoByYear,
                thumbnailLoader: makeThumbnailLoader()
            )
        )
    }
    
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard {
        return PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photoByMonth: photoByMonth,
                thumbnailLoader: makeThumbnailLoader()
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailLoader: makeThumbnailLoader()
            )
        )
    }
    
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell {
        return PhotoCell(
            viewModel: PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailLoader: makeThumbnailLoader(),
                nodeUseCase: NodeUseCaseFactory.makeNodeUseCase(for: contentMode)
            )
        )
    }
    
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity]) {
        tracker.trackAnalyticsEvent(with: DIContainer.singlePhotoSelectedEvent)
        
        guard var topController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        if topController.definesPresentationContext == false && topController.children.isEmpty { return }
        
        let displayMode = contentMode.displayMode
        let photoBrowser = MEGAPhotoBrowserViewController
            .photoBrowser(
                currentPhoto: photo,
                allPhotos: allPhotos,
                displayMode: displayMode)
        
        topController.modalPresentationStyle = .popover
        topController.present(photoBrowser, animated: true)
    }
    
    func openCameraUploadSettings(viewModel: PhotoLibraryModeAllViewModel) {
        CameraUploadsSettingsViewRouter(
            presenter: UIApplication.mnz_visibleViewController().navigationController,
            closure: { viewModel.invalidateCameraUploadEnabledSetting() })
        .start()
    }
    
    private func makeThumbnailLoader() -> any ThumbnailLoaderProtocol {
        ThumbnailLoaderFactory.makeThumbnailLoader(mode: contentMode)
    }
}

private extension PhotoLibraryContentMode {
    var displayMode: DisplayMode {
        switch self {
        case .library, .album, .mediaDiscovery:
            return .cloudDrive
        case .albumLink:
            return .albumLink
        case .mediaDiscoveryFolderLink:
            return .nodeInsideFolderLink
        }
    }
}
