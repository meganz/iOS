@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class PhotoBrowserDataProvider_nodeEntity_Tests: XCTestCase {
    func test_init_currentPhoto_partOfAllPhotos() async {
        let currentPhoto = MockNode(handle: 5)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7),
                         MockNode(handle: 6),
                         MockNode(handle: 5),
                         MockNode(handle: 4)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.currentIndex, 5)
        XCTAssertEqual(sut.count, 7)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.allPhotos, allPhotos)
        let successfulNode = await sut.photoNode(at: 0)
        XCTAssertEqual(successfulNode, NodeEntity(handle: 10).toMEGANode(in: sdk))
        let failedNode = await sut.photoNode(at: 100)
        XCTAssertEqual(failedNode, nil)
    }
    
    func test_init_currentPhoto_notPartOfAllPhotos() async {
        let currentPhoto = MockNode(handle: 50)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7),
                         MockNode(handle: 6),
                         MockNode(handle: 5),
                         MockNode(handle: 4)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        
        let results = await [sut.currentPhoto(), sut.photoNode(at: 6), sut.photoNode(at: 100)]
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.count, 7)
        XCTAssertEqual(results[0], NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(results[1], NodeEntity(handle: 4).toMEGANode(in: sdk))
        XCTAssertEqual(results[2], nil)
    }
    
    func test_shouldUpdateCurrentIndex_outOfRange() {
        let currentPhoto = MockNode(handle: 1)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos),
                                           nodeProvider: MockMEGANodeProvider())
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 3))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: -1))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 100))
    }
    
    func test_shouldUpdateCurrentIndex_inRange() {
        let currentPhoto = MockNode(handle: 3)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos),
                                           nodeProvider: MockMEGANodeProvider())
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 1))
        XCTAssertTrue(sut.shouldUpdateCurrentIndex(toIndex: 0))
        XCTAssertTrue(sut.shouldUpdateCurrentIndex(toIndex: 2))
    }
    
    @MainActor
    func test_removePhotos_removeAll() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos),
                                           nodeProvider: MockMEGANodeProvider())
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .removed)])
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 0)
        let removedNode = await sut.photoNode(at: 0)
        XCTAssertEqual(removedNode, nil)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos.isEmpty, true)
    }
    
    @MainActor
    func test_removePhotos_noRemove() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos),
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 4)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .attributes),
                                                    MockNode(handle: 9, changeType: .publicLink),
                                                    MockNode(handle: 8, changeType: .favourite),
                                                    MockNode(handle: 7, changeType: .inShare)])
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 4)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    @MainActor
    func test_removePhotos_removeCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .name)])
        
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 2)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentPhotoNodeEntity, NodeEntity(handle: 10))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 10), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_removePhotos_removePhotosBeforeCurrentOne() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
         
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .owner),
                                                    MockNode(handle: 8, changeType: .name)])
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 2)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 9), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_removePhotos_removePhotosAfterCurrentOne() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
          
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .name),
                                                    MockNode(handle: 8, changeType: .parent)])
        
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        
        XCTAssertEqual(sut.count, 2)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 10), NodeEntity(handle: 9)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndOneBeforeCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 11),
                         MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 4)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 8, changeType: .name)])
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 2)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, NodeEntity(handle: 11).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentPhotoNodeEntity, NodeEntity(handle: 11))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 11), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndAllPhotosBeforeCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))

        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 8, changeType: .name)])
        
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        
        XCTAssertEqual(sut.count, 1)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, NodeEntity(handle: 8).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentPhotoNodeEntity, NodeEntity(handle: 8))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndOneAfterCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 11),
                         MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 5)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .name),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 7, changeType: .parent)])
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 3)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentPhotoNodeEntity, NodeEntity(handle: 10))
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 11), NodeEntity(handle: 10), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndAllPhotosAfterCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))

        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .name),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .parent)])
        _ = sut.removePhotos(in: removingNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 1)
        let postRemovalResult = await sut.currentPhoto()
        XCTAssertEqual(postRemovalResult, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentPhotoNodeEntity, NodeEntity(handle: 10))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 10)].toMEGANodes(in: sdk))
    }
    
    @MainActor
    func test_updatePhotos_noUpdates() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
         
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos),
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))

        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let updateNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                  MockNode(handle: 9, changeType: .name),
                                                  MockNode(handle: 8, changeType: .parent)])
        sut.updatePhotos(in: updateNodeList.toNodeEntities())
        XCTAssertEqual(sut.count, 3)
        let postUpdateResult = await sut.currentPhoto()
        XCTAssertEqual(postUpdateResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    func test_updatePhotos_nameUpdates() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let nodeProvider = MockMEGANodeProvider(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: nodeProvider)
        XCTAssertEqual(sut.count, 3)
        let result = await sut.currentPhoto()
        XCTAssertEqual(result, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let updateNodeList = MockNodeList(nodes: [MockNode(handle: 10, name: "10-update", changeType: .attributes),
                                                  MockNode(handle: 9, name: "9-update", changeType: .name),
                                                  MockNode(handle: 8, name: "8-update", changeType: .publicLink)])
        sut.updatePhotos(in: updateNodeList.toNodeEntities())
        sdk.setNodes(updateNodeList.toNodeArray())
        nodeProvider.set(nodes: updateNodeList.toNodeArray())

        XCTAssertEqual(sut.count, 3)
        let postUpdateResult = await sut.currentPhoto()
        XCTAssertEqual(postUpdateResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let nodeResulst = await [sut.photoNode(at: 0), sut.photoNode(at: 1), sut.photoNode(at: 2), sut.photoNode(at: 3)]
        XCTAssertEqual(nodeResulst[0]?.name, "10-update")
        XCTAssertEqual(nodeResulst[1]?.name, "9-update")
        XCTAssertEqual(nodeResulst[2]?.name, "8-update")
        XCTAssertEqual(nodeResulst[3]?.name, nil)
    }
    
    func test_updatePhoto_notExistInRequest() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos),
                                           nodeProvider: MockMEGANodeProvider(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        let resut = await sut.currentPhoto()
        XCTAssertEqual(resut, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        sut.updatePhoto(by: MockRequest(handle: 100))
        
        XCTAssertEqual(sut.count, 3)
        let postUpdateResult = await sut.currentPhoto()
        XCTAssertEqual(postUpdateResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    func test_updatePhoto_existInRequest_nonCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let nodeProvider = MockMEGANodeProvider(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: nodeProvider)
        XCTAssertEqual(sut.count, 3)
        let resut = await sut.currentPhoto()
        XCTAssertEqual(resut, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        sut.updatePhoto(by: MockRequest(handle: 8))
        let updatedPhotos = [MockNode(handle: 10, name: "10-updated"),
                             MockNode(handle: 9, name: "9-updated"),
                             MockNode(handle: 8, name: "8-updated")]
        sdk.setNodes(updatedPhotos)
        nodeProvider.set(nodes: updatedPhotos)

        XCTAssertEqual(sut.count, 3)
        let postUpdateResult = await sut.currentPhoto()
        XCTAssertEqual(postUpdateResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, updatedPhotos)

        let nodeResulst = await [sut.photoNode(at: 0), sut.photoNode(at: 1), sut.photoNode(at: 2)]

        XCTAssertEqual(nodeResulst[0]?.name, "10-updated")
        XCTAssertEqual(nodeResulst[1]?.name, "9-updated")
        XCTAssertEqual(nodeResulst[2]?.name, "8-updated")
    }
    
    func test_updatePhoto_existInRequest_current() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let nodeProvider = MockMEGANodeProvider(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk,
                                           nodeProvider: nodeProvider)
        XCTAssertEqual(sut.count, 3)
        let resut = await sut.currentPhoto()
        XCTAssertEqual(resut, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        sut.updatePhoto(by: MockRequest(handle: 9))
        let updatedPhotos = [MockNode(handle: 10, name: "10-updated"),
                             MockNode(handle: 9, name: "9-updated"),
                             MockNode(handle: 8, name: "8-updated")]
        
        sdk.setNodes(updatedPhotos)
        nodeProvider.set(nodes: updatedPhotos)

        XCTAssertEqual(sut.count, 3)
        let postUpdateResult = await sut.currentPhoto()
        XCTAssertEqual(postUpdateResult, currentPhoto)
        XCTAssertEqual(sut.currentPhotoNodeEntity, currentPhoto.toNodeEntity())
        XCTAssertEqual(sut.currentIndex, 1)

        let nodeResulst = await [sut.photoNode(at: 0), sut.photoNode(at: 1), sut.photoNode(at: 2)]

        XCTAssertEqual(nodeResulst[0]?.name, "10-updated")
        XCTAssertEqual(nodeResulst[1]?.name, "9-updated")
        XCTAssertEqual(nodeResulst[2]?.name, "8-updated")
    }
}
