@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class PhotoBrowserViewModelTests: XCTestCase {
    
    func testOnViewDidLoad_called_shouldTrackPhotoPreviewEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.dispatch(.onViewDidLoad)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoPreviewScreenEvent()])
    }
    
    func testTrackAnalyticsSaveToDeviceMenuToolbarEvent_called_shouldTrackCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.trackAnalyticsSaveToDeviceMenuToolbarEvent()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoPreviewSaveToDeviceMenuToolbarEvent()])
    }
    
    func testTrackHideNodeMenuEvent_called_shouldTrackCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.trackHideNodeMenuEvent()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [ImagePreviewHideNodeMenuToolBarEvent()])
    }
    
    func testActionOnViewWillAppear_shouldInvokeNodesUpdateCommand() async {
        let nodeEntities = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2)
        ]
        let nodeRepository = MockNodeRepository(nodeUpdates: [nodeEntities].async.eraseToAnyAsyncSequence())
        let photoBrowserUseCase = MockPhotoBrowserUseCase(nodeRepository: nodeRepository)
        let sut = makeSUT(photoBrowserUseCase: photoBrowserUseCase)
        
        var invokedCommands = [PhotoBrowserViewModel.Command]()
        sut.invokeCommand = { command in
            invokedCommands.append(command)
        }
        
        sut.dispatch(.onViewWillAppear)
        
        var handles: [[HandleEntity]] = []
        for await nodeEntities in photoBrowserUseCase.nodeUpdates {
            handles.append(nodeEntities.map(\.handle))
        }
        
        XCTAssertEqual(handles, [[1, 2]])
        
        await test(viewModel: sut, action: .onViewWillAppear, expectedCommands: [.nodesUpdate(nodeEntities)])
    }

    func testActionOnViewWillDisappear_shouldCancelMonitorNodeUpdatesTask() {
        let sut = makeSUT()
        sut.dispatch(.onViewWillDisappear)
        XCTAssertNil(sut.monitorNodeUpdatesTask)
    }
    
    func testActionOnViewWillAppear_shouldMonitorNodeUpdatesTask() {
        let sut = makeSUT()
        sut.dispatch(.onViewWillAppear)
        XCTAssertNotNil(sut.monitorNodeUpdatesTask)
    }
    
    private func makeSUT(
        tracker: any AnalyticsTracking = MockTracker(),
        photoBrowserUseCase: any PhotoBrowserUseCaseProtocol = MockPhotoBrowserUseCase()
    ) -> PhotoBrowserViewModel {
        PhotoBrowserViewModel(
            tracker: tracker,
            photoBrowserUseCase: photoBrowserUseCase
        )
    }
}
