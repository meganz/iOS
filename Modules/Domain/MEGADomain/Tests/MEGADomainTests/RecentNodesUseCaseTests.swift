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
        let sut = sut(recentNodesRepository: mockRepo)
        
        let limitCount = Int.random(in: 0...10)
        let recentActionBuckets = try await sut.recentActionBuckets(limitCount: limitCount)
        
        XCTAssertTrue(recentActionBuckets.count <= limitCount, "Received \(recentActionBuckets.count) items which should be within the limit count of \(limitCount).")
        let invocations = mockRepo.invocations
        XCTAssertEqual(invocations, [.recentActionBuckets(limit: limitCount, excludeSensitive: false)])
    }
    
    func testRecentActionBuckets_whenGivenScenarioForSenetiveFlagSet_shouldFilterByProvidedSenstiveRequirements() async throws {
        let allRecentActionBucket = [RecentActionBucketEntity(parentHandle: 1),
                                     RecentActionBucketEntity(parentHandle: 2),
                                     RecentActionBucketEntity(parentHandle: 3),
                                     RecentActionBucketEntity(parentHandle: 4),
                                     RecentActionBucketEntity(parentHandle: 5),
                                     RecentActionBucketEntity(parentHandle: 6)]
        
        let scenarios: [(featureFlagActive: Bool, excludeSensitive: Bool?, expectedResult: Bool)] = [
            (false, true, false),
            (false, false, false),
            (false, nil, false),
            (true, true, true),
            (true, true, true),
            (true, false, false),
            (true, nil, true)
        ]
        
        for (featureFlagActive, excludeSensitive, expectedResult) in scenarios {
            
            let mockRepo = MockRecentNodesRepository(
                allRecentActionBucketList: allRecentActionBucket,
                requestResult: .success
            )
            let sut = sut(
                recentNodesRepository: mockRepo,
                hiddenNodesFeatureFlagEnabled: featureFlagActive)
            
            let limitCount = Int.random(in: 0...10)
            let recentActionBuckets = if let excludeSensitive {
                try await sut.recentActionBuckets(limitCount: limitCount, excludeSensitive: excludeSensitive)
            } else {
                try await sut.recentActionBuckets(limitCount: limitCount)
            }
            
            XCTAssertTrue(recentActionBuckets.count <= limitCount, "Received \(recentActionBuckets.count) items which should be within the limit count of \(limitCount).")
            XCTAssertEqual(
                mockRepo.invocations,
                [.recentActionBuckets(limit: limitCount, excludeSensitive: expectedResult)])
        }
    }
    
    func testRecentActionBuckets_withFailedResult_shouldThrowError() async throws {
        let mockRepo = MockRecentNodesRepository(
            requestResult: .failure(GenericErrorEntity())
        )
        let sut = sut(recentNodesRepository: mockRepo)
        let limitCount = Int.random(in: 0...10)

        await XCTAsyncAssertThrowsError(try await sut.recentActionBuckets(limitCount: limitCount)) { errorThrown in
            XCTAssertTrue(errorThrown is GenericErrorEntity)
        }
        XCTAssertEqual(mockRepo.invocations, [.recentActionBuckets(limit: limitCount, excludeSensitive: false)])
    }
}

extension RecentNodesUseCaseTests {
    func sut(
        recentNodesRepository: MockRecentNodesRepository = MockRecentNodesRepository(),
        contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(),
        hiddenNodesFeatureFlagEnabled: Bool = false
    ) -> RecentNodesUseCase<MockRecentNodesRepository, MockContentConsumptionUserAttributeUseCase> {
        RecentNodesUseCase(
            recentNodesRepository: recentNodesRepository,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { hiddenNodesFeatureFlagEnabled })
    }
}
