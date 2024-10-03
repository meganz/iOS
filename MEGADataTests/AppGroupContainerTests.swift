@testable import MEGA
import MEGASDKRepo
import XCTest

class AppGroupContainerTests: XCTestCase {
    private let url = URL(string: "http://mega.nz")
    private lazy var sut = AppGroupContainer(fileManager: MockFileManager(containerURL: url!))
    
    func testConatainerURL() throws {
        XCTAssertEqual(sut.url, try XCTUnwrap(url))
    }
    
    func testDirectoryURLs() throws {
        for directory in AppGroupContainer.Directory.allCases {
            let directoryURL = sut.url(for: directory)
            switch directory {
            case .cache:
                XCTAssertEqual(directoryURL, try XCTUnwrap(url?.appendingPathComponent("Library/Caches", isDirectory: true)))
            case .shareExtension:
                XCTAssertEqual(directoryURL, try XCTUnwrap(url?.appendingPathComponent("Share Extension Storage", isDirectory: true)))
            case .fileExtension:
                XCTAssertEqual(directoryURL, try XCTUnwrap(url?.appendingPathComponent("File Provider Storage", isDirectory: true)))
            case .logs:
                XCTAssertEqual(directoryURL, try XCTUnwrap(url?.appendingPathComponent("logs", isDirectory: true)))
            case .groupSupport:
                XCTAssertEqual(directoryURL, try XCTUnwrap(url?.appendingPathComponent("GroupSupport", isDirectory: true)))
            }
        }
    }
}
