import XCTest
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class AlbumContentsUpdateNotifierRepositoryTests: XCTestCase {
    
    func testOnAlbumReload_onChangeTypeNew_shouldBeCalled() {
        let mockSdk = MockSdk()
        let mockSDKNodeUpdateRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk, nodesUpdateListenerRepo: mockSDKNodeUpdateRepo)
        let changedNode = NodeEntity(changeTypes:[.new], handle:1)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.onAlbumReload = {
            exp.fulfill()
        }
        
        mockSDKNodeUpdateRepo.onNodesUpdateHandler?([changedNode])
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeAttributes_shouldBeCalled() {
        let mockSdk = MockSdk()
        let mockSDKNodeUpdateRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk, nodesUpdateListenerRepo: mockSDKNodeUpdateRepo)
        let changedNode = NodeEntity(changeTypes:[.attributes], handle:1)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.onAlbumReload = {
            exp.fulfill()
        }
        
        mockSDKNodeUpdateRepo.onNodesUpdateHandler?([changedNode])
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeParent_shouldBeCalled() {
        let mockSdk = MockSdk()
        let mockSDKNodeUpdateRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk, nodesUpdateListenerRepo: mockSDKNodeUpdateRepo)
        let changedNode = NodeEntity(changeTypes:[.parent], handle:1)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.onAlbumReload = {
            exp.fulfill()
        }
        
        mockSDKNodeUpdateRepo.onNodesUpdateHandler?([changedNode])
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypePublicLink_shouldBeCalled() {
        let mockSdk = MockSdk()
        let mockSDKNodeUpdateRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk, nodesUpdateListenerRepo: mockSDKNodeUpdateRepo)
        let changedNode = NodeEntity(changeTypes:[.publicLink], handle:1)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.onAlbumReload = {
            exp.fulfill()
        }
        
        mockSDKNodeUpdateRepo.onNodesUpdateHandler?([changedNode])
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onChangeTypeInShare_shouldNotBeCalled() {
        let mockSdk = MockSdk()
        let mockSDKNodeUpdateRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk, nodesUpdateListenerRepo: mockSDKNodeUpdateRepo)
        let changedNode = NodeEntity(changeTypes:[.inShare], handle:1)
        let exp = expectation(description: "OnAlbumReload should not be called.")
        exp.isInverted = true
        
        repo.onAlbumReload = {
            exp.fulfill()
        }
        
        mockSDKNodeUpdateRepo.onNodesUpdateHandler?([changedNode])
        
        wait(for: [exp], timeout: 0.5)
    }
    
    func testOnAlbumReload_onOneNodeInTrash_shouldBeCalled() {
        let node = MockNode(handle:1,changeType: .inShare)
        let mockSdk = MockSdk(rubbishBinNode: node)
        let mockSDKNodeUpdateRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let repo = AlbumContentsUpdateNotifierRepository(sdk: mockSdk, nodesUpdateListenerRepo: mockSDKNodeUpdateRepo)
        let exp = expectation(description: "OnAlbumReload should be called.")
        
        repo.onAlbumReload = {
            exp.fulfill()
        }
        
        let changedNodes = [node.toNodeEntity(), NodeEntity(changeTypes:[], handle:2)]
        mockSDKNodeUpdateRepo.onNodesUpdateHandler?(changedNodes)
        
        wait(for: [exp], timeout: 0.5)
    }
}
