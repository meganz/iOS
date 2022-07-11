import XCTest
@testable import MEGA

final class NodeActionViewModelTests: XCTestCase {
    
    func testSlideShow_withFeatureFlagEnable_shouldReturnTrue() throws {
        let mockNode = MockNode(handle: 1, name: "TestImage.png")
        let usecase = MockNodeActionUseCase(slideShowImages: [NodeEntity()])
        
        let viewModel = NodeActionViewModel(nodeActionUseCase: usecase)
        let result = viewModel.shouldShowSlideShow(with: mockNode.toNodeEntity(), featureFlag: true)
        
        XCTAssertTrue(result)
    }
    
    func testSlideShow_withFeatureFlagDisabled_shouldReturnFalse() throws {
        let mockNode = MockNode(handle: 1, name: "TestImage.png")
        let usecase = MockNodeActionUseCase(slideShowImages: [NodeEntity()])
        
        let viewModel = NodeActionViewModel(nodeActionUseCase: usecase)
        let result = viewModel.shouldShowSlideShow(with: mockNode.toNodeEntity(), featureFlag: false)
        
        XCTAssertFalse(result)
    }
    
    func testSlideShow_withFeatureFlagEnableWithNoImageNodes_shouldReturnFalse() throws {
        let mockNode = MockNode(handle: 1, name: "TestImage.png")
        let usecase = MockNodeActionUseCase(slideShowImages: [NodeEntity()])
        
        let viewModel = NodeActionViewModel(nodeActionUseCase: usecase)
        let result = viewModel.shouldShowSlideShow(with: mockNode.toNodeEntity(), featureFlag: false)
        
        XCTAssertFalse(result)
    }
}
