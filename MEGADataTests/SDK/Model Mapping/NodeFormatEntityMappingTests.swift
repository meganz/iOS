import XCTest
import MEGADomain
@testable import MEGA

final class NodeFormatEntityMappingTests: XCTestCase {
    
    func testMapToMEGANodeFormatType() {
        let sut: [NodeFormatEntity] = [.unknown, .audio, .video, .document, .photo]
        for type in sut {
            switch type {
            case .unknown:
                XCTAssertEqual(type.toMEGANodeFormatType(), .unknown)
            case .audio:
                XCTAssertEqual(type.toMEGANodeFormatType(), .audio)
            case .video:
                XCTAssertEqual(type.toMEGANodeFormatType(), .video)
            case .document:
                XCTAssertEqual(type.toMEGANodeFormatType(), .document)
            case .photo:
                XCTAssertEqual(type.toMEGANodeFormatType(), .photo)
            }
        }
    }
}
