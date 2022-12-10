import XCTest
import MEGADomain
import MEGADomainMock

final class FileExistUseCaseTests: XCTestCase {
    
    var fileUrl: URL {
        URL(fileURLWithPath: "")
    }
    
    func testFileExists_shouldReturnTrue() throws {
        let sut = FileExistUseCase(fileSystemRepository: MockFileSystemRepository(fileExists: true))
        XCTAssertTrue(sut.fileExists(at: fileUrl))
    }

    func testFileExists_shouldReturnFalse() throws {
        let sut = FileExistUseCase(fileSystemRepository: MockFileSystemRepository(fileExists: false))
        XCTAssertFalse(sut.fileExists(at: fileUrl))
    }
}
