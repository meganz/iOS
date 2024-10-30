@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGATest
import MEGAUIMock
import XCTest

final class HomeUploadingViewModelTests: XCTestCase {
    @MainActor
    private func makeSUT(tracker: some AnalyticsTracking = MockTracker()) -> HomeUploadingViewModel {
        HomeUploadingViewModel(
            uploadFilesUseCase: UploadPhotoAssetsUseCase(
                uploadPhotoAssetsRepository: UploadPhotoAssetsRepository(store: .shareInstance())
            ),
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            createContextMenuUseCase: MockCreateContextMenuUseCase(),
            tracker: tracker,
            router: FileUploadingRouter(baseViewController: UIViewController(), photoPicker: MockMEGAPhotoPicker())
        )
    }
    
    @MainActor
    private func trackAnalyticsEventTest(
        action: UploadAddActionEntity,
        expectedEvent: some EventIdentifier
    ) {
        let mockTracker = MockTracker()
        let sut = makeSUT(tracker: mockTracker)
        
        sut.uploadAddMenu(didSelect: action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }
    
    @MainActor
    private func verifyNetworkConnectivity(isConnected: Bool) async {
        let sut = makeSUT()
        
        sut.notifyUpdate = { outputs in
            XCTAssertEqual(outputs.networkReachable, isConnected)
        }
    }
    
    @MainActor
    func test_didTapUploadFromPhotoAlbum_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .chooseFromPhotos,
            expectedEvent: HomeChooseFromPhotosMenuToolbarEvent()
        )
    }
    
    @MainActor
    func test_didTapUploadFromImports_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .importFrom,
            expectedEvent: HomeImportFromFilesMenuToolbarEvent()
        )
    }
    
    @MainActor
    func testNetworkConnectivity_whenConnected_updatesIsConnectedToTrue() async {
        await verifyNetworkConnectivity(isConnected: true)
    }
    
    @MainActor
    func testNetworkConnectivity_whenNotConnected_updatesIsConnectedToFalse() async {
        await verifyNetworkConnectivity(isConnected: false)
    }
}
