@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepo
import XCTest

class FileCacheRepositoryTests: XCTestCase {
    func testTempFileURL() throws {
        let url = URL(string: "http://mega.nz")
        let sut = FileCacheRepository(fileManager: MockFileManager(tempURL: url!, containerURL: url!))
        let node = NodeEntity(name: "testNode", base64Handle: "testHandle")
        let expectedTempFileURL = try XCTUnwrap(url?.appendingPathComponent("testHandle").appendingPathComponent("testNode"))
        
        XCTAssertEqual(sut.tempFileURL(for: node), expectedTempFileURL)
    }
    
    func testCachedOriginalImageDirectoryURL() throws {
        let url = URL(string: "http://mega.nz")
        let sut = FileCacheRepository(fileManager: MockFileManager(tempURL: url!, containerURL: url!))
        let expectedTempFileURL = try XCTUnwrap(
            url?
                .appendingPathComponent("Library/Caches", isDirectory: true)
                .appendingPathComponent("originalV3", isDirectory: true)
        )
        
        XCTAssertEqual(sut.cachedOriginalImageDirectoryURL, expectedTempFileURL)
    }
    
    func testCachedOriginalImageURL() throws {
        let url = URL(string: "http://mega.nz")
        let sut = FileCacheRepository(fileManager: MockFileManager(tempURL: url!, containerURL: url!))
        let node = NodeEntity(name: "testImage", base64Handle: "testImageHandle")
        let expectedTempFileURL = try XCTUnwrap(
            url?
                .appendingPathComponent("Library/Caches", isDirectory: true)
                .appendingPathComponent("originalV3", isDirectory: true)
                .appendingPathComponent("testImageHandle", isDirectory: true)
                .appendingPathComponent("testImage", isDirectory: false)
        )
        
        XCTAssertEqual(sut.cachedOriginalImageURL(for: node), expectedTempFileURL)
    }
}
