import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

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

private class MockFileManager: FileManager {
    private let tempURL: URL
    private let containerURL: URL
    
    init(tempURL: URL, containerURL: URL) {
        self.tempURL = tempURL
        self.containerURL = containerURL
        super.init()
    }
    
    override var temporaryDirectory: URL {
        tempURL
    }
    
    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        containerURL
    }
}
