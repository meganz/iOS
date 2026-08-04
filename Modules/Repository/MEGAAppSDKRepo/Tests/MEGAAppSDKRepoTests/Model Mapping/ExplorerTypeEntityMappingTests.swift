import MEGADomain
import XCTest

final class ExplorerTypeEntityMappingTests: XCTestCase {
    
    func testMapToNodeFormatEntity() {
        let sut: [ExplorerTypeEntity] = [.audio, .video, .allDocs]
        for type in sut {
            switch type {
            case .audio:
                XCTAssertEqual(type.toNodeFormatEntity(), .audio)
            case .video:
                XCTAssertEqual(type.toNodeFormatEntity(), .video)
            case .allDocs:
                XCTAssertEqual(type.toNodeFormatEntity(), .allDocs)
            }
        }
    }
}
