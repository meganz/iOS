import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

@MainActor
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
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(contentMode: PhotoLibraryContentMode = .library,
         tracker: some AnalyticsTracking = DIContainer.tracker,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.contentMode = contentMode
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
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
                sensitiveNodeUseCase: makeSensitiveNodeUseCase(),
                featureFlagProvider: featureFlagProvider
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailLoader: makeThumbnailLoader(), 
                nodeUseCase: makeNodeUseCase(),
                sensitiveNodeUseCase: makeSensitiveNodeUseCase(),
                featureFlagProvider: featureFlagProvider
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
                featureFlagProvider: featureFlagProvider
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
        let nodeRepository = NodeRepository.newRepo
        return SensitiveNodeUseCase(nodeRepository: nodeRepository)
    }
}

extension PhotoLibraryContentMode {
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
