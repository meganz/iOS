import MEGADomain
import MEGADomainMock
import XCTest

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

    func testFileVerions_success_isEnabled() async throws {
        let repo = MockFileVersionsRepository(isFileVersionsEnabled: .success(true))
        let sut = FileVersionsUseCase(repo: repo)
        
        let enable = try await sut.isFileVersionsEnabled()
        
        XCTAssertTrue(enable)
    }
    
    func testFileVerions_success_isDisabled() async throws {
        let repo = MockFileVersionsRepository(isFileVersionsEnabled: .success(false))
        let sut = FileVersionsUseCase(repo: repo)
        
        let enable = try await sut.isFileVersionsEnabled()
        
        XCTAssertFalse(enable)
    }
    
    func testFileVerions_error_isEnabled() async {
        let mockError: FileVersionErrorEntity = .generic
        let repo = MockFileVersionsRepository(isFileVersionsEnabled: .failure(.generic))
        let sut = FileVersionsUseCase(repo: repo)
        
        do {
            _ = try await sut.isFileVersionsEnabled()
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? FileVersionErrorEntity)
        }
    }
        
    func testFileVerions_success_enableFileVersions() async throws {
        let repo = MockFileVersionsRepository(enableFileVersions: .success(true))
        let sut = FileVersionsUseCase(repo: repo)
        
        let enable = try await sut.enableFileVersions(true)
        
        XCTAssertTrue(enable)
    }
    
    func testFileVerions_success_disableFileVersions() async throws {
        let repo = MockFileVersionsRepository(enableFileVersions: .success(false))
        let sut = FileVersionsUseCase(repo: repo)
        
        let enable = try await sut.enableFileVersions(false)
        
        XCTAssertFalse(enable)
    }
    
    func testFileVerions_error_enableFileVersions() async {
        let mockError: FileVersionErrorEntity = .generic
        let repo = MockFileVersionsRepository(enableFileVersions: .failure(.generic))
        let sut = FileVersionsUseCase(repo: repo)
        
        do {
            _ = try await sut.enableFileVersions(true)
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? FileVersionErrorEntity)
        }
    }
    
    func testFileVerions_success_deletePreviousVersions() async throws {
        let repo = MockFileVersionsRepository(deletePreviousFileVersions: .success(true))
        let sut = FileVersionsUseCase(repo: repo)
        
        let delete = try await sut.deletePreviousFileVersions()
        
        XCTAssertTrue(delete)
    }
    
    func testFileVerions_error_deletePreviousVersions() async {
        let mockError: FileVersionErrorEntity = .generic
        let repo = MockFileVersionsRepository(enableFileVersions: .failure(.generic))
        let sut = FileVersionsUseCase(repo: repo)
        
        do {
            _ = try await sut.deletePreviousFileVersions()
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? FileVersionErrorEntity)
        }
    }
}
