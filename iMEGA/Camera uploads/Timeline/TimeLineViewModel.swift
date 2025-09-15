import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwiftUI
import SwiftUI

@MainActor
final class TimeLineViewModel: ObservableObject {
    
    @Published var cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel
    @Published var showEmptyStateView = false
    private let cameraUploadsSettingsViewRouter: any Routing
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private(set) var isCameraUploadsEnabled: Bool
    
    init(cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         cameraUploadsSettingsViewRouter: some Routing) {
        self.cameraUploadStatusBannerViewModel = cameraUploadStatusBannerViewModel
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
    
    func emptyScreenTypeToShow(
        filterType: PhotosFilterOptions,
        filterLocation: PhotosFilterOptions
    ) -> PhotosEmptyScreenViewType {
        guard !isCameraUploadsEnabled else {
            return .noMediaFound
        }
        return switch [filterType, filterLocation] {
        case [.images, .cloudDrive]:
                .noImagesFound
        case [.videos, .cloudDrive]:
                .noVideosFound
        case [.allMedia, .allLocations], [.allMedia, .cameraUploads],
            [.images, .allLocations], [.images, .cameraUploads],
            [.videos, .allLocations], [.videos, .cameraUploads]:
                .enableCameraUploads
        default: .noMediaFound
        }
    }
    
    func enableCameraUploadsBannerAction(filterLocation: PhotosFilterOptions) -> (() -> Void)? {
        guard shouldShowEnableCameraUploadsBanner(filterLocation: filterLocation) else {
            return nil
        }
        return navigateToCameraUploadSettings
    }
    
    func navigateToCameraUploadSettings() {
        cameraUploadsSettingsViewRouter.start()
    }
    
    private func shouldShowEnableCameraUploadsBanner(filterLocation: PhotosFilterOptions) -> Bool {
        guard !isCameraUploadsEnabled else {
            return false
        }
        return filterLocation == .cloudDrive
    }
}

extension PhotosEmptyScreenViewType {
    var centerImage: Image {
        switch self {
        case .noVideosFound:
            MEGAAssets.Image.videoEmptyState
        default:
            MEGAAssets.Image.allPhotosEmptyState
        }
    }
    
    var title: String {
        switch self {
        case .noImagesFound:
            Strings.Localizable.Home.Images.empty
        case .noVideosFound:
            Strings.Localizable.noVideosFound
        default:
            Strings.Localizable.CameraUploads.Timeline.AllMedia.Empty.title
        }
    }
}
