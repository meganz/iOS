@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeCollectionViewCellViewModelTests: XCTestCase {

    func testIsNodeVideo_videoName_shouldBeTrue() {
        let mockUsecase = MockMediaUseCase(isStringVideo: true)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        XCTAssertTrue(viewModel.isNodeVideo(name: "video.mp4"))
    }
    
    func testIsNodeVideo_imageName_shouldBeFalse() {
        let mockUsecase = MockMediaUseCase(isStringVideo: false)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        XCTAssertFalse(viewModel.isNodeVideo(name: "image.png"))
    }
    
    func testIsNodeVideo_noName_shouldBeFalse() {
        let mockUsecase = MockMediaUseCase(isStringVideo: false)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        XCTAssertFalse(viewModel.isNodeVideo(name: ""))
    }
    
    func testIsNodeVideoWithValidDuration_withVideo_validDuration_shouldBeTrue() {
        let mockUsecase = MockMediaUseCase(isStringVideo: true)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        let mockNode = MockNode(handle: 1, name: "video.mp4", duration: 10)
        XCTAssertTrue(viewModel.isNodeVideoWithValidDuration(node: mockNode))
    }
    
    func testIsNodeVideoWithValidDuration_withVideo_zeroDuration_shouldBeTrue() {
        let mockUsecase = MockMediaUseCase(isStringVideo: true)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        let mockNode = MockNode(handle: 1, name: "video.mp4", duration: 0)
        XCTAssertTrue(viewModel.isNodeVideoWithValidDuration(node: mockNode))
    }
    
    func testIsNodeVideoWithValidDuration_withVideo_invalidDuration_shouldBeFalse() {
        let mockUsecase = MockMediaUseCase(isStringVideo: true)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        let mockNode = MockNode(handle: 1, name: "video.mp4", duration: -1)
        XCTAssertFalse(viewModel.isNodeVideoWithValidDuration(node: mockNode))
    }
    
    func testIsNodeVideoWithValidDuration_notVideo_shouldBeFalse() {
        let mockUsecase = MockMediaUseCase(isStringVideo: false)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        let mockNode = MockNode(handle: 1, name: "image.png", duration: 0)
        XCTAssertFalse(viewModel.isNodeVideoWithValidDuration(node: mockNode))
    }
    
    func testIsNodeVideoWithValidDuration_noName_shouldBeFalse() {
        let mockUsecase = MockMediaUseCase(isStringVideo: false)
        let viewModel = NodeCollectionViewCellViewModel(mediaUseCase: mockUsecase)
        
        let mockNode = MockNode(handle: 1, name: "", duration: 0)
        XCTAssertFalse(viewModel.isNodeVideoWithValidDuration(node: mockNode))
    }
    
}
