import XCTest
@testable import MEGA

final class CheckLocalPathUseCaseTests: XCTestCase {

    func test_containsOriginalCacheDirectory() {
        let repo = FileSystemRepository(fileManager: FileManager.default)
        let sut = CheckLocalPathUseCase(repo: repo)
        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.mega.ios")!.appendingPathComponent("Library").appendingPathComponent("Caches").appendingPathComponent("originalV3").path
        let result = sut.containsOriginalCacheDirectory(path: path)
        XCTAssertTrue(result)
    }
    
    func test_doesnot_containsOriginalCacheDirectory() {
        let repo = FileSystemRepository(fileManager: FileManager.default)
        let sut = CheckLocalPathUseCase(repo: repo)
        let result = sut.containsOriginalCacheDirectory(path: "/test/ab")
        XCTAssertFalse(result)
    }
    
}
