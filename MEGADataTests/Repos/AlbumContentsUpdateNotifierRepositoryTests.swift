import Combine
@testable import MEGA
import MEGADataMock
import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumContentsUpdateNotifierRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testOnAlbumReload_onChangeTypeNew_shouldBeCalled() {
        let mockSdk = MockSdk()
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk)
        let changedNode = MockNode(handle: 1, changeType: .new)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeAttributes_shouldBeCalled() {
        let mockSdk = MockSdk()
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk)
        let changedNode = MockNode(handle: 1, changeType: .attributes)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeParent_shouldBeCalled() {
        let mockSdk = MockSdk()
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk)
        let changedNode = MockNode(handle: 1, changeType: .parent)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypePublicLink_shouldBeCalled() {
        let mockSdk = MockSdk()
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk)
        let changedNode = MockNode(handle: 1, changeType: .publicLink)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeInShare_shouldNotBeCalled() {
        let mockSdk = MockSdk()
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk)
        let changedNode = MockNode(handle: 1, changeType: .inShare)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        repo.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: [changedNode]))
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onOneNodeInTrash_shouldBeCalled() {
        let node = MockNode(handle: 1, changeType: .inShare)
        let mockSdk = MockSdk(rubbishBinNode: node)
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.albumReloadPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let changedNodes = [node, MockNode(handle: 2, changeType: .timestamp)]
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: changedNodes))
        
        wait(for: [exp], timeout: 0.5)
    }
}
