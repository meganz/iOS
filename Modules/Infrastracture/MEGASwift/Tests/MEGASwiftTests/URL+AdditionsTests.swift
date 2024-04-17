@testable import MEGASwift
import XCTest

final class URLAdditionsTests: XCTestCase {
    private let url = URL(fileURLWithPath: "/path/to/file.txt")
    
    func testFileExtensionPath_shouldReturnThePathExtension() {
        let expectedFileExtension = "txt"
        
        let fileExtension = url[keyPath: URL.fileExtensionPath]
        
        XCTAssertEqual(fileExtension, expectedFileExtension)
    }
}
