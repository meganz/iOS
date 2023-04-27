import XCTest
@testable import MEGA
import MEGADomain
import MEGADataMock

final class PhotoBrowserDataProvider_nodeEntity_Tests: XCTestCase {
    func test_init_currentPhoto_partOfAllPhotos() {
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
                                           sdk: sdk)
        XCTAssertEqual(sut.currentIndex, 5)
        XCTAssertEqual(sut.count, 7)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(sut[0], NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut[100], nil)
    }
    
    func test_init_currentPhoto_notPartOfAllPhotos() {
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
                                           sdk: sdk)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.count, 7)
        XCTAssertEqual(sut.currentPhoto, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(sut[6], NodeEntity(handle: 4).toMEGANode(in: sdk))
        XCTAssertEqual(sut[100], nil)
    }
    
    func test_shouldUpdateCurrentIndex_outOfRange() {
        let currentPhoto = MockNode(handle: 1)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 3))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: -1))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 100))
    }
    
    func test_shouldUpdateCurrentIndex_inRange() {
        let currentPhoto = MockNode(handle: 3)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 1))
        XCTAssertTrue(sut.shouldUpdateCurrentIndex(toIndex: 0))
        XCTAssertTrue(sut.shouldUpdateCurrentIndex(toIndex: 2))
    }
    
    func test_removePhotos_removeAll() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .removed)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.currentPhoto, nil)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos.isEmpty, true)
    }
    
    func test_removePhotos_noRemove() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7)]
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .attributes),
                                                    MockNode(handle: 9, changeType: .publicLink),
                                                    MockNode(handle: 8, changeType: .favourite),
                                                    MockNode(handle: 7, changeType: .inShare)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    func test_removePhotos_removeCurrent() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .name)])
        
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 10), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    func test_removePhotos_removePhotosBeforeCurrentOne() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .owner),
                                                    MockNode(handle: 8, changeType: .name)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 9), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    func test_removePhotos_removePhotosAfterCurrentOne() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .name),
                                                    MockNode(handle: 8, changeType: .parent)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 10), NodeEntity(handle: 9)].toMEGANodes(in: sdk))
    }
    
    func test_removePhotos_removeCurrentAndOneBeforeCurrent() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 11),
                         MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 8, changeType: .name)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, NodeEntity(handle: 11).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle:11), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    func test_removePhotos_removeCurrentAndAllPhotosBeforeCurrent() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 8, changeType: .name)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.currentPhoto, NodeEntity(handle: 8).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    func test_removePhotos_removeCurrentAndOneAfterCurrent() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 11),
                         MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 5)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .name),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 7, changeType: .parent)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 11), NodeEntity(handle: 10), NodeEntity(handle: 8)].toMEGANodes(in: sdk))
    }
    
    func test_removePhotos_removeCurrentAndAllPhotosAfterCurrent() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .name),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .parent)])
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.currentPhoto, NodeEntity(handle: 10).toMEGANode(in: sdk))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [NodeEntity(handle: 10)].toMEGANodes(in: sdk))
    }
    
    func test_updatePhotos_noUpdates() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let updateNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                  MockNode(handle: 9, changeType: .name),
                                                  MockNode(handle: 8, changeType: .parent)])
        sut.updatePhotos(in: updateNodeList)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    func test_updatePhotos_nameUpdates() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let updateNodeList = MockNodeList(nodes: [MockNode(handle: 10, name: "10-update", changeType: .attributes),
                                                  MockNode(handle: 9, name: "9-update", changeType: .name),
                                                  MockNode(handle: 8, name: "8-update", changeType: .publicLink)])
        sdk.setNodes(updateNodeList.toNodeArray())
        sut.updatePhotos(in: updateNodeList)

        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        XCTAssertEqual(sut[0]?.name, "10-update")
        XCTAssertEqual(sut[1]?.name, "9-update")
        XCTAssertEqual(sut[2]?.name, "8-update")
        XCTAssertEqual(sut[3]?.name, nil)
    }
    
    func test_updatePhoto_notExistInRequest() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        sut.updatePhoto(by: MockRequest(handle: 100))
        
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    func test_updatePhoto_existInRequest_nonCurrent() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        sut.updatePhoto(by: MockRequest(handle: 8))
        let updatedPhotos = [MockNode(handle: 10, name: "10-updated"),
                             MockNode(handle: 9, name: "9-updated"),
                             MockNode(handle: 8, name: "8-updated")]
        sdk.setNodes(updatedPhotos)
        
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, updatedPhotos)
        
        XCTAssertEqual(sut[0]?.name, "10-updated")
        XCTAssertEqual(sut[1]?.name, "9-updated")
        XCTAssertEqual(sut[2]?.name, "8-updated")
    }
    
    func test_updatePhoto_existInRequest_current() {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(),
                                           allPhotos: allPhotos.toNodeEntities(),
                                           sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        sut.updatePhoto(by: MockRequest(handle: 9))
        let updatedPhotos = [MockNode(handle: 10, name: "10-updated"),
                             MockNode(handle: 9, name: "9-updated"),
                             MockNode(handle: 8, name: "8-updated")]
        sdk.setNodes(updatedPhotos)
        
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)

        XCTAssertEqual(sut[0]?.name, "10-updated")
        XCTAssertEqual(sut[1]?.name, "9-updated")
        XCTAssertEqual(sut[2]?.name, "8-updated")
    }
}
