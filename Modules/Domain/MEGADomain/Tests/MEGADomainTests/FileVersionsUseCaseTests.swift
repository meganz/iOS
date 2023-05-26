
import XCTest
import MEGADomain
import MEGADomainMock

final class FileVersionsUseCaseTests: XCTestCase {
    
    func testFileVersions_matchCurrentCount() {
        let versions: Int64 = 4
        let repo = MockFileVersionsRepository(versions: versions)
        let sut = FileVersionsUseCase(repo: repo)
        XCTAssertEqual(sut.rootNodeFileVersionCount(), versions)
    }
    
    func testFileVersionsSize_matchCurrentSize() {
        let versionsSize: Int64 = 368640
        let repo = MockFileVersionsRepository(versionsSize: versionsSize)
        let sut = FileVersionsUseCase(repo: repo)
        XCTAssertEqual(sut.rootNodeFileVersionTotalSizeInBytes(), versionsSize)
    }

    func testFileVerions_success_isEnabled() {
        let repo = MockFileVersionsRepository(isFileVersionsEnabled: .success(true))
        let sut = FileVersionsUseCase(repo: repo)
        sut.isFileVersionsEnabled { result in
            switch result {
            case .success(let enable):
                XCTAssertTrue(enable)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func testFileVerions_success_isDisabled() {
        let repo = MockFileVersionsRepository(isFileVersionsEnabled: .success(false))
        let sut = FileVersionsUseCase(repo: repo)
        sut.isFileVersionsEnabled { result in
            switch result {
            case .success(let enable):
                XCTAssertFalse(enable)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func testFileVerions_error_isEnabled() {
        let mockError: FileVersionErrorEntity = .generic
        
        let repo = MockFileVersionsRepository(isFileVersionsEnabled: .failure(.generic))
        let sut = FileVersionsUseCase(repo: repo)
        sut.isFileVersionsEnabled { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
        
    func testFileVerions_success_enableFileVersions() {
        let repo = MockFileVersionsRepository(enableFileVersions: .success(true))
        let sut = FileVersionsUseCase(repo: repo)
        sut.enableFileVersions(true) { result in
            switch result {
            case .success(let enable):
                XCTAssertTrue(enable)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func testFileVerions_success_disableFileVersions() {
        let repo = MockFileVersionsRepository(enableFileVersions: .success(false))
        let sut = FileVersionsUseCase(repo: repo)
        sut.enableFileVersions(false) { result in
            switch result {
            case .success(let enable):
                XCTAssertFalse(enable)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func testFileVerions_error_enableFileVersions() {
        let mockError: FileVersionErrorEntity = .generic
        
        let repo = MockFileVersionsRepository(enableFileVersions: .failure(.generic))
        let sut = FileVersionsUseCase(repo: repo)
        sut.enableFileVersions(true) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func testFileVerions_success_deletePreviousVersions() {
        let repo = MockFileVersionsRepository(deletePreviousFileVersions: .success(true))
        let sut = FileVersionsUseCase(repo: repo)
        sut.deletePreviousFileVersions { result in
            switch result {
            case .success(let delete):
                XCTAssertTrue(delete)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func testFileVerions_error_deletePreviousVersions() {
        let mockError: FileVersionErrorEntity = .generic
        
        let repo = MockFileVersionsRepository(enableFileVersions: .failure(.generic))
        let sut = FileVersionsUseCase(repo: repo)
        sut.deletePreviousFileVersions { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
}
