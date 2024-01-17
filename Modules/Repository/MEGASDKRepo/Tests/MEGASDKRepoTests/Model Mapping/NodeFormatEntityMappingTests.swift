import MEGADomain
import MEGASdk
import XCTest

final class NodeFormatEntityMappingTests: XCTestCase {
    
    func testMapToMEGANodeFormatType() {
        let sut: [NodeFormatEntity] = [
            .unknown,
            .photo,
            .audio,
            .video,
            .document,
            .pdf,
            .presentation,
            .archive,
            .program,
            .misc,
            .spreadsheet,
            .allDocs
        ]
        let expectedValues: [MEGANodeFormatType] = [
            .unknown,
            .photo,
            .audio,
            .video,
            .document,
            .pdf,
            .presentation,
            .archive,
            .program,
            .misc,
            .spreadsheet,
            .allDocs
        ]
        for type in zip(sut, expectedValues) {
            XCTAssertEqual(type.0.toMEGANodeFormatType(), type.1, "mapper does not work for \(type.0)")
        }
    }
}
