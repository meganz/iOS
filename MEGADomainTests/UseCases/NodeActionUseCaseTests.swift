import XCTest
@testable import MEGA

final class NodeActionUseCaseTests: XCTestCase {
    
    func testSlideShow_withImageNode_shouldReturnNodes() throws {
        var repo = MockNodeRepository()
        let mockNode = MockNode(handle: 1, name: "TestImage.png")
        
        repo.images = [mockNode.toNodeEntity()]
        
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withVideoNode_shouldReturnEmpty() throws {
        let repo = MockNodeRepository()
        let mockNode = MockNode(handle: 1, name: "TestVideo.mp4")
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
    
    func testSlideShow_withFileNode_shouldReturnEmpty() throws {
        let repo = MockNodeRepository()
        let mockNode = MockNode(handle: 1, name: "TestFile.txt")
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
    
    func testSlideShow_withFolderContainsImageNode_shouldReturnNodes() throws {
        var repo = MockNodeRepository()
        repo.images = [NodeEntity()]
        
        let mockNode = MockNode(handle: 1, name: "TestFolder", nodeType: .folder)
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withFolderNotContainsImageNode_shouldReturnEmpty() throws {
        let repo = MockNodeRepository()
        let mockNode = MockNode(handle: 1, name: "TestFolder", nodeType: .folder)
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
}
