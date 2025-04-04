import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class AppDistributionRepositoryTests: XCTestCase {
    
    func testCheckForUpdate_whenError_deliversNil() async {
        let sut = makeSUT(result: .failure(anyError()))
        
        let resultEntity = try? await sut.checkForUpdate()
        
        XCTAssertNil(resultEntity)
    }
    
    func testCheckForUpdate_whenHasNilResult_deliversNil() async {
        let sut = makeSUT(result: .success(nil))
        
        let resultEntity = try? await sut.checkForUpdate()
        
        XCTAssertNil(resultEntity)
    }
    
    func testCheckForUpdate_whenHasEntityResult_deliversEntity() async {
        let expectedEntity = anyReleaseEntity()
        let sut = makeSUT(result: .success(expectedEntity))
        
        let resultEntity = try? await sut.checkForUpdate()
        
        XCTAssertEqual(resultEntity, expectedEntity)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(result: Result<AppDistributionReleaseEntity?, any Error>) -> AppDistributionRepository {
        let appUpdateChecker = MockAppUpdateChecker(result: result)
        let sut = AppDistributionRepository(appUpdateChecker: appUpdateChecker)
        return sut
    }
    
    private func anyReleaseEntity() -> AppDistributionReleaseEntity {
        AppDistributionReleaseEntity(
            displayVersion: anyString(),
            buildVersion: anyString(),
            downloadURL: anyURL()
        )
    }
    
    private func anyError() -> NSError {
        NSError(domain: "any-error", code: 1)
    }
    
    private func anyURL() -> URL {
        URL(string: "any-url.com")!
    }
    
    private func anyString() -> String {
        "any-string"
    }
}
