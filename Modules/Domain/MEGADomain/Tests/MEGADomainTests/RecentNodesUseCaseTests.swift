import MEGADomain
import MEGADomainMock
import XCTest

final class RecentNodesUseCaseTests: XCTestCase {

    func testRecentActionBuckets_withLimitCountLessThanTheList_shouldReturnRecentActionBucketEntityList() async throws {
        let allRecentActionBucket = [RecentActionBucketEntity(parentHandle: 1),
                                     RecentActionBucketEntity(parentHandle: 2),
                                     RecentActionBucketEntity(parentHandle: 3),
                                     RecentActionBucketEntity(parentHandle: 4),
                                     RecentActionBucketEntity(parentHandle: 5),
                                     RecentActionBucketEntity(parentHandle: 6)]
        
        let mockRepo = MockRecentNodesRepository(
            allRecentActionBucketList: allRecentActionBucket,
            requestResult: .success
        )
        let sut = RecentNodesUseCase(repo: mockRepo)
        
        let limitCount = Int.random(in: 0...10)
        let recentActionBuckets = try await sut.recentActionBuckets(limitCount: limitCount)
        
        XCTAssertTrue(recentActionBuckets.count <= limitCount, "Received \(recentActionBuckets.count) items which should be within the limit count of \(limitCount).")
    }
    
    func testRecentActionBuckets_withFailedResult_shouldThrowError() async throws {
        let mockRepo = MockRecentNodesRepository(
            requestResult: .failure(GenericErrorEntity())
        )
        let sut = RecentNodesUseCase(repo: mockRepo)
        
        await XCTAsyncAssertThrowsError(try await sut.recentActionBuckets(limitCount: 5)) { errorThrown in
            XCTAssertTrue(errorThrown is GenericErrorEntity)
        }
    }
}
