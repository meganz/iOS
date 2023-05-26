import XCTest
@testable import MEGASwift

final class MEGASwiftTests: XCTestCase {
    func testBase64Encoded() throws {
        let string = "Hello, MEGA!"
        let base64Encoded = try XCTUnwrap(string.base64Encoded)
        XCTAssertEqual(base64Encoded, "SGVsbG8sIE1FR0Eh")
    }
    
    func testBase64Decoded() throws {
        let base64Encoded = "SGVsbG8sIE1FR0Eh"
        let string = try XCTUnwrap(base64Encoded.base64Decoded)
        XCTAssertEqual(string, "Hello, MEGA!")
    }
    
    func testBase64Decoded_stringOmittingASinglePadding_shouldMatch() throws {
        let base64Encoded = "MTI6MDA"
        let string = try XCTUnwrap(base64Encoded.base64Decoded)
        XCTAssertEqual(string, "12:00")
    }
    
    func testBase64Decoded_stringOmittingMultiplePadding_shouldMatch() throws {
        let base64Encoded = "TWVldGluZyAxMzozOA"
        let string = try XCTUnwrap(base64Encoded.base64Decoded)
        XCTAssertEqual(string, "Meeting 13:38")
    }
    
    func testMemoryStyleString() {
        let oneMegaInBytes: Int64 = 1048576
        let onMegaString = "1 MB"
        XCTAssertEqual(onMegaString, String.memoryStyleString(fromByteCount: oneMegaInBytes))
    }
}
