@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class HomeUploadingViewModelTests: XCTestCase {
    private func makeSUT(tracker: AnalyticsTracking) -> HomeUploadingViewModel {
        HomeUploadingViewModel(
            uploadFilesUseCase: UploadPhotoAssetsUseCase(
                uploadPhotoAssetsRepository: UploadPhotoAssetsRepository(store: .shareInstance())
            ),
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            createContextMenuUseCase: MockCreateContextMenuUseCase(),
            tracker: tracker,
            router: FileUploadingRouter(baseViewController: UIViewController())
        )
    }
    
    private func trackAnalyticsEventTest(
        action: UploadAddActionEntity,
        expectedEvent: EventIdentifier
    ) {
        let mockTracker = MockTracker()
        let sut = makeSUT(tracker: mockTracker)
        
        sut.uploadAddMenu(didSelect: action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }

    func test_didTapUploadFromPhotoAlbum_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .chooseFromPhotos,
            expectedEvent: HomeChooseFromPhotosMenuToolbarEvent()
        )
    }

    func test_didTapUploadFromImports_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .importFrom,
            expectedEvent: HomeImportFromFilesMenuToolbarEvent()
        )
    }
}
