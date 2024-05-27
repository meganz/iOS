import Foundation
import XCTest

public extension XCTestCase {
    
    func makeImageURL(systemImageName: String = "folder", file: StaticString = #filePath, line: UInt = #line) throws -> URL {
        let localImage = try XCTUnwrap(UIImage(systemName: systemImageName), "Expect to create system image, but failed with nil value.", file: file, line: line)
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated, "Expect local image to be created, but not created.", file: file, line: line)
        
        addTeardownBlock {
            let path = if #available(iOS 16.0, *) {
                localURL.path()
            } else {
                localURL.path
            }
            try FileManager.default.removeItem(atPath: path)
        }
        
        return localURL
    }
}
