import XCTest
@testable import MEGA

final class NodeActionUseCaseTests: XCTestCase {
    
    func testSlideShow_withImageNode_shouldReturnNodes() throws {
        var repo = MockNodeActionRepository()
        let mockNode = MockNodeWithTypeAndParent(name: "TestImage.png", nodeType: .image, handle: 1, parentHandle: 0)
        
        repo.images = [mockNode.toNodeEntity()]
        
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withVideoNode_shouldReturnEmpty() throws {
        let repo = MockNodeActionRepository()
        let mockNode = MockNodeWithTypeAndParent(name: "TestVideo.mp4", nodeType: .video, handle: 1, parentHandle: 0)
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
    
    func testSlideShow_withFileNode_shouldReturnEmpty() throws {
        let repo = MockNodeActionRepository()
        let mockNode = MockNodeWithTypeAndParent(name: "TestFile.txt", nodeType: .file, handle: 1, parentHandle: 0)
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
    
    func testSlideShow_withFolderContainsImageNode_shouldReturnNodes() throws {
        var repo = MockNodeActionRepository()
        repo.images = [NodeEntity()]
        
        let mockNode = MockNodeWithTypeAndParent(name: "TestFolder", nodeType: .folder, handle: 1, parentHandle: 0)
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 1)
    }
    
    func testSlideShow_withFolderNotContainsImageNode_shouldReturnEmpty() throws {
        let repo = MockNodeActionRepository()
        let mockNode = MockNodeWithTypeAndParent(name: "TestFolder", nodeType: .folder, handle: 1, parentHandle: 0)
        let usecase = NodeActionUseCase(repo: repo)
        
        let images = usecase.slideShowImages(for: mockNode.toNodeEntity())
        
        XCTAssertTrue(images.count == 0)
    }
}
