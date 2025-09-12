import ContentLibraries
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissionsMock
import MEGAPreference
import Testing

struct TimeLineViewModelTests {
    
    @MainActor
    @Suite("Empty View")
    struct EmptyView {
        @Test("Camera upload enabled ensure correct no media found empty type returned")
        func emptyViewCameraUploadEnabled() {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true]))
            let emptyScreenType = sut.emptyScreenTypeToShow(
                filterType: .allMedia, filterLocation: .allLocations)
            #expect(emptyScreenType == .noMediaFound)
        }
        
        @Test("Ensure the correct empty view type is shown for filter when camera upload is not enabled",
              arguments: [
                (filterType: PhotosFilterOptions.allMedia,
                 filterLocation: PhotosFilterOptions.allLocations, expectedViewType: PhotosEmptyScreenViewType.enableCameraUploads),
                (filterType: .allMedia, filterLocation: .cloudDrive, expectedViewType: .noMediaFound),
                (filterType: .allMedia, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                (filterType: .images, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                (filterType: .images, filterLocation: .cloudDrive, expectedViewType: .noImagesFound),
                (filterType: .images, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                (filterType: .videos, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                (filterType: .videos, filterLocation: .cloudDrive, expectedViewType: .noVideosFound),
                (filterType: .videos, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads)
              ])
        func emptyViewType(
            filterType: PhotosFilterOptions,
            filterLocation: PhotosFilterOptions,
            expectedViewType: PhotosEmptyScreenViewType
        ) async throws {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false]))
            let emptyScreenType = sut.emptyScreenTypeToShow(
                filterType: filterType, filterLocation: filterLocation)
            #expect(emptyScreenType == expectedViewType)
        }
    }
    
    @MainActor
    @Test(arguments: [
        (PhotosFilterOptions.allLocations, true, false),
        (PhotosFilterOptions.allLocations, false, false),
        (PhotosFilterOptions.cloudDrive, false, true)
    ])
    func enableCameraBannerAction(
        location: PhotosFilterOptions,
        cameraUploadEnabled: Bool,
        actionShouldRoute: Bool
    ) {
        let cameraUploadsSettingsViewRouter = MockRouter()
        let sut = Self.makeSUT(
            preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: cameraUploadEnabled]),
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        let action = sut.enableCameraUploadsBannerAction(filterLocation: location)
        if actionShouldRoute {
            action?()
            #expect(cameraUploadsSettingsViewRouter.startCalled == 1)
        } else {
            #expect(action == nil)
        }
    }
    
    @MainActor
    private static func makeSUT(
        cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel = .init(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(),
            devicePermissionHandler: MockDevicePermissionHandler(),
            cameraUploadsSettingsViewRouter: MockRouter()),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter()
    ) -> TimeLineViewModel {
        .init(
            cameraUploadStatusBannerViewModel: cameraUploadStatusBannerViewModel,
            preferenceUseCase: preferenceUseCase,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
    }
}
