import XCTest
@testable import MEGA

@available(iOS 14.0, *)
class MediaDiscoveryViewModelTests: XCTestCase {
    
    func testAction_onViewReady_withEmptyMediaFiles() throws {
        let parentNode = MEGANode()
        let router = MediaDiscoveryRouter(viewController: nil, parentNode: parentNode)
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: router)
        
        test(viewModel: viewModel, action: MediaDiscoveryAction.onViewReady, expectedCommands: [.loadMedia(nodes: [])])
    }
    
    func testAction_onNodesUpdate_shouldNotReload() throws {
        let parentNode = MEGANode()
        let router = MediaDiscoveryRouter(viewController: nil, parentNode: parentNode)
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode, router: router)
        
        test(viewModel: viewModel, action: MediaDiscoveryAction.onNodesUpdate(nodeList: MEGANodeList()), expectedCommands: [])
    }
}
