import XCTest
@testable import MEGA
import MEGADomain

final class MediaDiscoveryViewModelTests: XCTestCase {
    func testAction_onViewReady_withEmptyMediaFiles() throws {
        let parentNode = MEGANode()
        let router = MediaDiscoveryRouter(viewController: nil, parentNode: parentNode)
        let usecase = MockMediaDiscoveryStatsUseCase()
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: router, statsUseCase: usecase)
        
        test(viewModel: viewModel, action: MediaDiscoveryAction.onViewReady, expectedCommands: [.loadMedia(nodes: [])])
    }
    
    func testAction_onNodesUpdate_shouldNotReload() throws {
        let parentNode = MEGANode()
        let router = MediaDiscoveryRouter(viewController: nil, parentNode: parentNode)
        let usecase = MockMediaDiscoveryStatsUseCase()
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: router, statsUseCase: usecase)
        
        test(viewModel: viewModel, action: MediaDiscoveryAction.onNodesUpdate(nodeList: MEGANodeList()), expectedCommands: [])
    }
    
    func testSendEvent_onMediaDiscoveryVisited_shouldReturnTrue() throws {
        let parentNode = MEGANode()
        let router = MediaDiscoveryRouter(viewController: nil, parentNode: parentNode)
        let usecase = MockMediaDiscoveryStatsUseCase()
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: router, statsUseCase: usecase)
        
        test(viewModel: viewModel, action: MediaDiscoveryAction.onViewDidAppear, expectedCommands: [])
        
        XCTAssertTrue(usecase.hasPageVisitedCalled)
    }
    
    func testSendEvent_onMediaDiscoveryExit_shouldReturnTrue() throws {
        let parentNode = MEGANode()
        let router = MediaDiscoveryRouter(viewController: nil, parentNode: parentNode)
        let usecase = MockMediaDiscoveryStatsUseCase()
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: router, statsUseCase: usecase)
        
        test(viewModel: viewModel, action: MediaDiscoveryAction.onViewWillDisAppear, expectedCommands: [])
        
        XCTAssertTrue(usecase.hasPageStayCalled)
    }
}
