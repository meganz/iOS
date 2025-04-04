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
    
    init(contentMode: PhotoLibraryContentMode = .library,
         tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.contentMode = contentMode
        self.tracker = tracker
    }
    
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard {
        return PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photoByYear: photoByYear,
                thumbnailLoader: makeThumbnailLoader(),
                nodeUseCase: makeNodeUseCase(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase()
            )
        )
    }
    
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard {
        return PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photoByMonth: photoByMonth,
                thumbnailLoader: makeThumbnailLoader(),
                nodeUseCase: makeNodeUseCase(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase()
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailLoader: makeThumbnailLoader(),
                nodeUseCase: makeNodeUseCase(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase()
            )
        )
    }
    
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell {
        return PhotoCell(
            viewModel: PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailLoader: makeThumbnailLoader(),
                nodeUseCase: NodeUseCaseFactory.makeNodeUseCase(for: contentMode),
                sensitiveNodeUseCase: SensitiveNodeUseCaseFactory.makeSensitiveNodeUseCase(for: contentMode)
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
    
    private func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
          nodeDataRepository: NodeDataRepository.newRepo,
          nodeValidationRepository: NodeValidationRepository.newRepo,
          nodeRepository: NodeRepository.newRepo)
    }
    
    private func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
    }
}

extension PhotoLibraryContentMode {
    var displayMode: DisplayMode {
        switch self {
        case .library:
            .photosTimeline
        case .album:
            .photosAlbum
        case .mediaDiscovery:
            .cloudDrive
        case .albumLink:
            .albumLink
        case .mediaDiscoveryFolderLink:
            .nodeInsideFolderLink
        }
    }
}

