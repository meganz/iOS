import XCTest
import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class MediaDiscoveryViewModelTests: XCTestCase {
    private var router: MediaDiscoveryRouter!
    private var analyticsUseCase: MockMediaDiscoveryAnalyticsUseCase!
    
    private let parentNode = NodeEntity()
    private var nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        router = MediaDiscoveryRouter(viewController: nil, parentNode: MockNode(handle: 0))
        analyticsUseCase = MockMediaDiscoveryAnalyticsUseCase()
    }
    
    // MARK: - Action Command tests
    
    func testAction_onViewReady_withEmptyMediaFiles() throws {
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher))
        let sut = MediaDiscoveryViewModel(parentNode: parentNode, router: router,
                                      analyticsUseCase: analyticsUseCase, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.loadMedia(nodes: [])])
    }
    
    func testAction_onViewReady_loadedNodesRequestLoadMedia() throws {
        let expected = [NodeEntity(handle: 1)]
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expected)
        let sut = MediaDiscoveryViewModel(parentNode: parentNode, router: router,
                                      analyticsUseCase: analyticsUseCase, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.loadMedia(nodes: expected)])
    }
    
    func testSendEvent_onMediaDiscoveryVisited_shouldReturnTrue() throws {
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher))
        let sut = MediaDiscoveryViewModel(parentNode: parentNode, router: router,
                                      analyticsUseCase: analyticsUseCase, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.loadMedia(nodes: [])])
        
        XCTAssertTrue(analyticsUseCase.hasPageVisitedCalled)
    }
    
    func testSendEvent_onMediaDiscoveryExit_shouldReturnTrue() throws {
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher))
        let sut = MediaDiscoveryViewModel(parentNode: parentNode, router: router,
                                      analyticsUseCase: analyticsUseCase, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        test(viewModel: sut, action: .onViewWillDisAppear, expectedCommands: [])
        
        XCTAssertTrue(analyticsUseCase.hasPageStayCalled)
    }
    
    // MARK: - Node updates tests
    
    func testSubscription_onNodesUpdate_shouldReload() throws {
        let expectedNodes = [NodeEntity(handle: 1)]
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expectedNodes)
        let sut = MediaDiscoveryViewModel(parentNode: parentNode, router: router,
                                      analyticsUseCase: analyticsUseCase, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        var results = [[NodeEntity]]()
        let loadMediaExpectation = expectation(description: "load and reload triggers")
        loadMediaExpectation.expectedFulfillmentCount = 2
        
        sut.invokeCommand = { command in
            switch command {
            case .loadMedia(nodes: let nodes):
                results.append(nodes)
                loadMediaExpectation.fulfill()
            }
        }
        sut.dispatch(.onViewReady)

        nodeUpdatesPublisher.send([NodeEntity(handle: 2)])
        
        wait(for: [loadMediaExpectation], timeout: 2)
        XCTAssertEqual(results.first, expectedNodes)
        XCTAssertEqual(results.last, expectedNodes)
    }
    
    func testSubscription_onNodesUpdate_shouldDoNothingIfReloadIsNotRequired() throws {
        let expectedNodes = [NodeEntity(handle: 1)]
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expectedNodes,
                                                              shouldReload: false)
        let sut = MediaDiscoveryViewModel(parentNode: parentNode, router: router,
                                      analyticsUseCase: analyticsUseCase, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        let loadMediaExpectation = expectation(description: "should not trigger reload")
        loadMediaExpectation.isInverted = true
        
        sut.invokeCommand = { command in
            switch command {
            case .loadMedia(nodes: _):
                loadMediaExpectation.fulfill()
            }
        }
        nodeUpdatesPublisher.send([NodeEntity(handle: 2)])
        
        wait(for: [loadMediaExpectation], timeout: 2)
    }
}
