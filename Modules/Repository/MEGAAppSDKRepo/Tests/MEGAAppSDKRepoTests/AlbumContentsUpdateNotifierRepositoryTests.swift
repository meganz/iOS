import Combine
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGATest
import XCTest

final class AlbumContentsUpdateNotifierRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testOnAlbumReload_onChangeTypeNewWithoutVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let changedNode = anyNode(changeType: .new, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeAttributeWithoutVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let changedNode = anyNode(changeType: .attributes, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeParentWithoutVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let changedNode = anyNode(changeType: .parent, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypePublicLinkWithoutVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let changedNode = anyNode(changeType: .publicLink, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeInShareWithoutVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let changedNode = anyNode(changeType: .inShare, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onOneNodeInTrashWithoutVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let node = anyNode(handle: 1, changeType: .inShare, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk(rubbishBinNode: node)
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let changedNodes = [node, anyNode(handle: 2, changeType: .timestamp, isVisualMediaAndHasThumbnail: false)]
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: changedNodes))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeNewWithVisualMediaNodeAndThumbnail_shouldBeCalled() {
        let changedNode = anyNode(changeType: .new, isVisualMediaAndHasThumbnail: true)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeAttributesWithVisualMediaNodeAndThumbnail_shouldBeCalled() {
        let changedNode = anyNode(changeType: .attributes, isVisualMediaAndHasThumbnail: true)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeParentWithVisualMediaNodeAndThumbnail_shouldBeCalled() {
        let changedNode = anyNode(changeType: .parent, isVisualMediaAndHasThumbnail: true)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypePublicLinkWithVisualMediaNodeAndThumbnail_shouldBeCalled() {
        let changedNode = anyNode(changeType: .publicLink, isVisualMediaAndHasThumbnail: true)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeInShareWithVisualMediaNodeAndThumbnail_shouldNotBeCalled() {
        let changedNode = anyNode(changeType: .inShare, isVisualMediaAndHasThumbnail: true)
        let mockSdk = MockSdk()
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_visualMediaNodeInTrash_shouldBeCalled() {
        let rubbishBinNode = MockNode(handle: 1)
        let mockSdk = MockSdk(rubbishBinNode: rubbishBinNode)
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let changedNodes = [MockNode(handle: 232, name: "test.jpg", parentHandle: rubbishBinNode.handle)]
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: changedNodes))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onNodeSensitivityChanged_shouldPublishToPublisher() {
        let node = anyNode(handle: 1, changeType: .inShare, isVisualMediaAndHasThumbnail: false)
        let mockSdk = MockSdk(rubbishBinNode: node)
        let sut = makeSUT(sdk: mockSdk)
        let exp = expectation(description: "album reload publisher should be emit item")
        
        sut.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let changedNodes = [node,
                            anyNode(handle: 76, changeType: .sensitive, isVisualMediaAndHasThumbnail: true)]
        sut.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: changedNodes))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(sdk: MockSdk, file: StaticString = #filePath, line: UInt = #line) -> AlbumContentsUpdateNotifierRepository {
        let sut = AlbumContentsUpdateNotifierRepository(sdk: sdk)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func anyNode(handle: MEGAHandle = 1, changeType: MEGANodeChangeType, isVisualMediaAndHasThumbnail: Bool) -> MockNode {
        isVisualMediaAndHasThumbnail
        ? MockNode(handle: handle, name: "any-visual-media-file.mp4", changeType: changeType, hasThumbnail: true)
        : MockNode(handle: handle, changeType: changeType)
    }
    
}
