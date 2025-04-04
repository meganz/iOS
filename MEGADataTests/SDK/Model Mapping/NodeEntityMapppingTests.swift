@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeEntityMapperTests: XCTestCase {
    func testMediaType_forNodeWithImageExtensionName_shouldReturnImage() {
        ImageFileExtensionEntity().imagesSupportedExtensions.enumerated().forEach {
            let node = MockNode(handle: HandleEntity($0.offset + 1), name: "Test.\($0.element)")
            XCTAssertEqual(node.toNodeEntity().mediaType, .image)
        }
    }
    
    func testMediaType_forNodeWithRawImageFileExtensionName_shouldReturnImage() {
        RawImageFileExtensionEntity().imagesSupportedExtensions.enumerated().forEach {
            let node = MockNode(handle: HandleEntity($0.offset + 1), name: "Test.\($0.element)")
            XCTAssertEqual(node.toNodeEntity().mediaType, .image)
        }
    }
    
    func testMediaType_forNodeWithVideoImageFileExtensionName_shouldReturnVideo() {
        VideoFileExtensionEntity().videoSupportedExtensions.enumerated().forEach {
            let node = MockNode(handle: HandleEntity($0.offset + 1), name: "Test.\($0.element)")
            XCTAssertEqual(node.toNodeEntity().mediaType, .video)
        }
    }
    
    func testMediaType_forNodeWithOtherExtension_shouldReturnNil() {
        let node = MockNode(handle: 1, name: "Test.txt").toNodeEntity()
        XCTAssertNil(node.mediaType)
    }
}
