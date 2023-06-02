import XCTest
import Foundation

final class EncodableTests: XCTestCase {

    func testConvertToDictionary_shouldReturnDictionary() throws {
        struct Timeline: Codable {
            var mediaType: String
            var location: String
        }
        
        struct Container: Codable {
            var timeline: Timeline
        }
        
        let json = """
        {
            "timeline": {
                "mediaType": "images",
                "location": "cameraUploads"
            }
        }
        """.data(using: .utf8)
        
        let container = try XCTUnwrap(JSONDecoder().decode(Container.self, from: XCTUnwrap(json)))

        let dictionary = try container.timeline.convertToDictionary()
        XCTAssertEqual(try XCTUnwrap(dictionary["mediaType"] as? String), "images")
        XCTAssertEqual(try XCTUnwrap(dictionary["location"] as? String), "cameraUploads")
    }

}
