@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGATest
import XCTest

final class HomeUploadingViewModelTests: XCTestCase {
    private func makeSUT(tracker: AnalyticsTracking = MockTracker()) -> HomeUploadingViewModel {
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
    
    @MainActor
    private func verifyNetworkConnectivity(isConnected: Bool) async {
        let networkUseCase = MockNetworkMonitorUseCase(
            connected: isConnected,
            connectionSequence: AsyncStream { continuation in
                continuation.yield(isConnected)
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT()
        
        sut.notifyUpdate = { outputs in
            XCTAssertEqual(outputs.networkReachable, isConnected)
        }
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
    
    @MainActor
    func testNetworkConnectivity_whenConnected_updatesIsConnectedToTrue() async {
        await verifyNetworkConnectivity(isConnected: true)
    }
    
    @MainActor
    func testNetworkConnectivity_whenNotConnected_updatesIsConnectedToFalse() async {
        await verifyNetworkConnectivity(isConnected: false)
    }
}
