import XCTest
@testable import MEGA
import MEGADataMock

final class PhotoBrowserDataProvider_megaNode_Tests: XCTestCase {
    func test_init_currentPhoto_partOfAllPhotos() {
        let currentPhoto = MockNode(handle: 1)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(sut[0], MockNode(handle: 2))
        XCTAssertEqual(sut[100], nil)
    }
    
    func test_init_currentPhoto_notPartOfAllPhotos() {
        let currentPhoto = MockNode(handle: 10)
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 2))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(sut[2], MockNode(handle: 1))
        XCTAssertEqual(sut[100], nil)
    }
    
    func test_init_currentIndex_inTheIndexRange() {
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentIndex: 2, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 1))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(sut[0], MockNode(handle: 2))
        XCTAssertEqual(sut[100], nil)
    }
    
    func test_init_currentIndex_notInTheIndexRange() {
        let allPhotos = [MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 1)]
        
        let sut = PhotoBrowserDataProvider(currentIndex: 1000, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 2))
        XCTAssertEqual(sut.allPhotos, allPhotos)
        XCTAssertEqual(sut[1], MockNode(handle: 3))
        XCTAssertEqual(sut[100], nil)
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
    
    func test_removePhotos_removeAll() {
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
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
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
        
        
        let sut = PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: MockSdk(nodes: allPhotos))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, allPhotos)
        
        
        let removingNodeList = MockNodeList(nodes: [MockNode(handle: 10, changeType: .publicLink),
                                                    MockNode(handle: 9, changeType: .parent),
                                                    MockNode(handle: 8, changeType: .name)])
        
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 10))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 10), MockNode(handle: 8)])
    }
    
    func test_removePhotos_removePhotosBeforeCurrentOne() {
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
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 9), MockNode(handle: 8)])
    }
    
    func test_removePhotos_removePhotosAfterCurrentOne() {
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
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, currentPhoto)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 10), MockNode(handle: 9)])
    }
    
    func test_removePhotos_removeCurrentAndOneBeforeCurrent() {
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
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 11))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle:11), MockNode(handle: 8)])
    }
    
    func test_removePhotos_removeCurrentAndAllPhotosBeforeCurrent() {
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
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 8))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 8)])
    }
    
    func test_removePhotos_removeCurrentAndOneAfterCurrent() {
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
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 10))
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 11), MockNode(handle: 10), MockNode(handle: 8)])
    }
    
    func test_removePhotos_removeCurrentAndAllPhotosAfterCurrent() {
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
        sut.removePhotos(in: removingNodeList)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.currentPhoto, MockNode(handle: 10))
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.allPhotos, [MockNode(handle: 10)])
    }
    
    func test_updatePhotos_noUpdates() {
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
    
    func test_updatePhotos_nameUpdates() {
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
        
        XCTAssertEqual(sut[0]?.name, "10-update")
        XCTAssertEqual(sut[1]?.name, "9")
        XCTAssertEqual(sut[2]?.name, "8-update")
        XCTAssertEqual(sut[3]?.name, nil)
    }
    
    func test_updateCurrentPhoto_notExistInRequest() {
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
    
    func test_updatePhoto_existInRequest_nonCurrent() {
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
        
        XCTAssertEqual(sut[0]?.name, "10")
        XCTAssertEqual(sut[1]?.name, "9")
        XCTAssertEqual(sut[2]?.name, "8-updated")
    }
    
    func test_updatePhoto_existInRequest_current() {
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

        XCTAssertEqual(sut[0]?.name, "10")
        XCTAssertEqual(sut[1]?.name, "9-updated")
        XCTAssertEqual(sut[2]?.name, "8")
    }
}
