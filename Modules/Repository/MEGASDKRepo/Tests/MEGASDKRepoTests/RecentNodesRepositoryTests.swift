import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGATest
import XCTest

final class RecentNodesRepositoryTests: XCTestCase {
    
    func testRecentActionBuckets_withSuccessResult_shouldReturnRecentActionBucketEntityList() async throws {
        let allRecentActionsBuckets = [MockRecentActionBucket(),
                                       MockRecentActionBucket(),
                                       MockRecentActionBucket(),
                                       MockRecentActionBucket(),
                                       MockRecentActionBucket(),
                                       MockRecentActionBucket()]
        let sdk = MockSdk(
            requestResult: .success(
                MockRequest(
                    handle: 1,
                    recentActionsBuckets: allRecentActionsBuckets
                )
            )
        )
        
        let sut = RecentNodesRepository(sdk: sdk)
        let recentActionBuckets = try await sut.recentActionBuckets(excludeSensitive: false)
        
        XCTAssertEqual(recentActionBuckets.count, allRecentActionsBuckets.count)
    }
    
    func testRecentActionBuckets_withFailedResult_shouldThrowError() async throws {
        let sdk = MockSdk(requestResult: .failure(MockError.failingError))
        let sut = RecentNodesRepository(sdk: sdk)
        
        do {
            _ = try await sut.recentActionBuckets(excludeSensitive: false)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
}
