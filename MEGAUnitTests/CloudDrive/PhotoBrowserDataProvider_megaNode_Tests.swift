@testable import MEGA
import MEGAAppSDKRepoMock
import XCTest

final class PhotoBrowserDataProvider_megaNode_Tests: XCTestCase {
    func test_init_currentPhoto_partOfAllPhotos() async {
        let currentPhoto = MockNode(handle: 1)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        
        let results = await [sut.photoNode(at: 0), sut.photoNode(at: 100)]

        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(results[0], MockNode(handle: 2))
        XCTAssertEqual(results[1], nil)
    }
    
    func test_init_currentPhoto_notPartOfAllPhotos() async {
        let currentPhoto = MockNode(handle: 10)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        
        let results = await [sut.photoNode(at: 2), sut.photoNode(at: 100)]

        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 2))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(results[0], MockNode(handle: 1))
        XCTAssertNil(results[1])
    }
    
    func test_init_currentIndex_inTheIndexRange() async {
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentIndex: 2, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        let results = await [sut.photoNode(at: 0), sut.photoNode(at: 100)]
        
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 1))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(results[0], MockNode(handle: 2))
        XCTAssertNil(results[1])
    }
    
    func test_init_currentIndex_notInTheIndexRange() async {
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentIndex: 1000, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        let nodes = await [sut.photoNode(at: 1), sut.photoNode(at: 100)]
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 2))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(nodes[0], MockNode(handle: 3))
        XCTAssertNil(nodes[1])
    }
    
    func test_shouldUpdateCurrentIndex_outOfRange() {
        let currentPhoto = MockNode(handle: 1)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 3))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: -1))
        XCTAssertFalse(sut.shouldUpdateCurrentIndex(toIndex: 100))
    }
    
    func test_shouldUpdateCurrentIndex_inRange() {
        let currentPhoto = MockNode(handle: 3)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
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
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .removed)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.currentPhoto, nil)
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
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .attributes),
                                                    MockNode(handle: 9, changeType: .publicLink),
                                                    MockNode(handle: 8, changeType: .favourite),
                                                    MockNode(handle: 7, changeType: .inShare)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
    }
    
    @MainActor
    func test_removePhotos_removeCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
         
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .name)])
        
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 8))
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 10), MockNode(handle: 8)])
    }
    
    @MainActor
    func test_removePhotos_removePhotosBeforeCurrentOne() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
                
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .owner),
                                                    MockNode(handle: 8, changeType: .name)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 9), MockNode(handle: 8)])
    }
    
    @MainActor
    func test_removePhotos_removePhotosAfterCurrentOne() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
         
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .name),
                                                    MockNode(handle: 8, changeType: .parent)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 10), MockNode(handle: 9)])
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndOneBeforeCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 11),
                         MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 8, changeType: .name)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 8))
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 11), MockNode(handle: 8)])
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndAllPhotosBeforeCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .removed),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 8, changeType: .name)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 8))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 8)])
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndOneAfterCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 11),
                         MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8),
                         MockNode(handle: 7)]
         
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 5)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .name),
                                                    MockNode(handle: 9, changeType: .removed),
                                                    MockNode(handle: 7, changeType: .parent)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 8))
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 11), MockNode(handle: 10), MockNode(handle: 8)])
    }
    
    @MainActor
    func test_removePhotos_removeCurrentAndAllPhotosAfterCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .name),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .parent)])
        _ = await sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 10))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 10)])
    }
    
    func test_updatePhotos_noUpdates() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
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
    
    func test_updatePhotos_nameUpdates() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let updateNodeList = MockNodeList(nodes: [MockNode(handle: 10, name: "10-update", changeType: .attributes),
                                                  MockNode(handle: 9, name: "9-update", changeType: .name),
                                                  MockNode(handle: 8, name: "8-update", changeType: .publicLink)])
        sut.updatePhotos(in: updateNodeList)
        
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let nodes = await [sut.photoNode(at: 0), sut.photoNode(at: 1), sut.photoNode(at: 2), sut.photoNode(at: 3)]
        
        XCTAssertEqual(nodes[0]?.name, "10-update")
        XCTAssertEqual(nodes[1]?.name, "9")
        XCTAssertEqual(nodes[2]?.name, "8-update")
        XCTAssertEqual(nodes[3]?.name, nil)
    }
    
    func test_updateCurrentPhoto_notExistInRequest() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10),
                         MockNode(handle: 9),
                         MockNode(handle: 8)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
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
    
    func test_updatePhoto_existInRequest_nonCurrent() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let updatedPhotos = [MockNode(handle: 10, name: "10-updated"),
                             MockNode(handle: 9, name: "9-updated"),
                             MockNode(handle: 8, name: "8-updated")]
        sdk.setNodes(updatedPhotos)
        sut.updatePhoto(by: MockRequest(handle: 8))
        
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, updatedPhotos)
        
        let nodes = await [sut.photoNode(at: 0), sut.photoNode(at: 1), sut.photoNode(at: 2)]

        XCTAssertEqual(nodes[0]?.name, "10")
        XCTAssertEqual(nodes[1]?.name, "9")
        XCTAssertEqual(nodes[2]?.name, "8-updated")
    }
    
    func test_updatePhoto_existInRequest_current() async {
        let currentPhoto = MockNode(handle: 9)
        let allPhotos = [MockNode(handle: 10, name: "10"),
                         MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sdk = MockSdk(nodes: allPhotos)
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: sdk)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        let updatedPhotos = [MockNode(handle: 10, name: "10-updated"),
                             MockNode(handle: 9, name: "9-updated"),
                             MockNode(handle: 8, name: "8-updated")]
        sdk.setNodes(updatedPhotos)
        sut.updatePhoto(by: MockRequest(handle: 9))
        
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        let nodes = await [sut.photoNode(at: 0), sut.photoNode(at: 1), sut.photoNode(at: 2)]

        XCTAssertEqual(nodes[0]?.name, "10")
        XCTAssertEqual(nodes[1]?.name, "9-updated")
        XCTAssertEqual(nodes[2]?.name, "8")
    }
    
    @MainActor
    func test_removePhotos_withUnchangedNodeCount_doesNotCauseNameOverride() async {
        let currentPhoto = MockNode(handle: 9, name: "9")
        let allPhotos = [MockNode(handle: 9, name: "9"),
                         MockNode(handle: 8, name: "8")]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.allPhotos.map { $0.name }, ["9", "8"])
        
        let update = MockNodeList(nodes: [MockNode(handle: 9, name: "9_update", changeType: .attributes)])
        sut.updatePhotos(in: update)
        
        let update2 = MockNodeList(nodes: [MockNode(handle: 9, name: "9"),
                                          MockNode(handle: 8, name: "8")])
        // this is called but none of the nodes have attibute removed
        _ = await sut.removePhotos(in: Optional(update2))
        XCTAssertEqual(sut.allPhotos.map { $0.name }, ["9_update", "8"])
    }
}
