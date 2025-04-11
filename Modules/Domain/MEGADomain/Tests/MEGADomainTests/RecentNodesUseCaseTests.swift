import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite
struct RecentNodesUseCaseTests {
    @Suite("Recent Action Buckets")
    struct RecentActionBucketsTests {
        @Test("Limit count less than the list")
        func shouldReturnRecentActionBucketEntityList() async throws {
            let allRecentActionBucket = (1...6).map { RecentActionBucketEntity(parentHandle: $0) }
            
            let mockRepo = MockRecentNodesRepository(
                allRecentActionBucketList: allRecentActionBucket,
                requestResult: .success
            )
            let sut = sut(recentNodesRepository: mockRepo)
            
            let limitCount = Int.random(in: 0...10)
            let recentActionBuckets = try await sut.recentActionBuckets(limitCount: limitCount)
            
            #expect(recentActionBuckets.count <= limitCount)
            let invocations = mockRepo.invocations
            #expect(invocations == [.recentActionBuckets(limit: limitCount, excludeSensitive: false)])
        }
        
        @Test(
            "When sensitive flag is set",
            arguments: [
                (featureFlagActive: false, excludeSensitive: true, expectedResult: false),
                (featureFlagActive: false, excludeSensitive: false, expectedResult: false),
                (featureFlagActive: false, excludeSensitive: nil, expectedResult: false),
                (featureFlagActive: true, excludeSensitive: true, expectedResult: true),
                (featureFlagActive: true, excludeSensitive: false, expectedResult: false),
                (featureFlagActive: true, excludeSensitive: nil, expectedResult: true)
            ]
        )
        func shouldFilterByProvidedSenstiveRequirements(
            arguments: (featureFlagActive: Bool, excludeSensitive: Bool?, expectedResult: Bool)
        ) async throws {
            let allRecentActionBucket = (1...6).map { RecentActionBucketEntity(parentHandle: $0) }
            
            let mockRepo = MockRecentNodesRepository(
                allRecentActionBucketList: allRecentActionBucket,
                requestResult: .success
            )
            let sut = sut(
                recentNodesRepository: mockRepo,
                hiddenNodesFeatureFlagEnabled: arguments.featureFlagActive)
            
            let limitCount = Int.random(in: 0...10)
            let recentActionBuckets = if let excludeSensitive = arguments.excludeSensitive {
                try await sut.recentActionBuckets(limitCount: limitCount, excludeSensitive: excludeSensitive)
            } else {
                try await sut.recentActionBuckets(limitCount: limitCount)
            }
            
            #expect(recentActionBuckets.count <= limitCount)
            #expect(mockRepo.invocations == [.recentActionBuckets(limit: limitCount, excludeSensitive: arguments.expectedResult)])
        }
        
        @Test("When RecentNodesRepository returns failure")
        func shouldThrowError() async throws {
            let mockRepo = MockRecentNodesRepository(
                requestResult: .failure(GenericErrorEntity())
            )
            let sut = sut(recentNodesRepository: mockRepo)
            let limitCount = Int.random(in: 0...10)

            await #expect(performing: {
                try await sut.recentActionBuckets(limitCount: limitCount)
            }, throws: { errorThrown in
                errorThrown is GenericErrorEntity
            })
            
            #expect(mockRepo.invocations == [.recentActionBuckets(limit: limitCount, excludeSensitive: false)])
        }
    }
    
    @Suite("Recent action buckets updates")
    struct RecentActionBucketsUpdatesTests {
        @Test(
            "User updates",
            arguments: zip([UserEntity.ChangeTypeEntity.CCPrefs, .cookieSetting], [true, false])
        )
        func shouldYieldRecentActionBucketsUpdates(userChangeType: UserEntity.ChangeTypeEntity, shouldYieldUpdates: Bool) async throws {
            let userUpdateRepository = MockUserUpdateRepository(
                usersUpdates: [[UserEntity(changes: userChangeType)]].async.eraseToAnyAsyncSequence()
            )
            let sut = sut(userUpdateRepository: userUpdateRepository)
            
            var iterator = sut.recentActionBucketsUpdates.makeAsyncIterator()
            let result = await iterator.next() != nil
            
            #expect(result == shouldYieldUpdates)
        }
        
        @Test(
            "Request finish updates",
            arguments: zip(
                [
                    RequestResponseEntity(requestEntity: .init(type: .fetchNodes), error: .init(type: .ok)),
                    RequestResponseEntity(requestEntity: .init(type: .login), error: .init(type: .ok)),
                    RequestResponseEntity(requestEntity: .init(type: .fetchNodes), error: .init(type: .badArguments))
                ],
                [true, false, false]
                
            )
            
        )
        func shouldYieldRecentActionBucketsUpdates(requestResponseEntity: RequestResponseEntity, shouldYieldUpdates: Bool) async throws {
            let requestStatesRepository = MockRequestStatesRepository(requestFinishUpdates: [requestResponseEntity].async.eraseToAnyAsyncSequence())
            let sut = sut(requestStatesRepository: requestStatesRepository)
            
            var iterator = sut.recentActionBucketsUpdates.makeAsyncIterator()
            let result = await iterator.next() != nil
            
            #expect(result == shouldYieldUpdates)
        }
        
        @Test(
            "Node updates",
            arguments: zip(
                [
                    NodeEntity(changeTypes: .removed, handle: 1, isFolder: true),
                    NodeEntity(changeTypes: .removed, handle: 2, isFolder: false),
                    NodeEntity(changeTypes: .new, handle: 3, isFolder: true),
                    NodeEntity(changeTypes: .name, handle: 4, isFolder: true),
                    NodeEntity(changeTypes: .new, handle: 5, isFolder: false),
                    NodeEntity(changeTypes: .name, handle: 6, isFolder: false)
                ],
                [false, false, false, true, true, true]
            )
        )
        func shouldYieldRecentActionBucketsUpdates(
            nodeEntity: NodeEntity,
            shouldYieldUpdates: Bool
        ) async throws {
            let nodeRepository = MockNodeRepository(
                nodeUpdates: [
                    [nodeEntity]
                ].async.eraseToAnyAsyncSequence()
            )
            let sut = sut(nodeRepository: nodeRepository)
            
            var iterator = sut.recentActionBucketsUpdates.makeAsyncIterator()
            let result = await iterator.next() != nil
            
            #expect(result == shouldYieldUpdates)
        }
    }
}

extension RecentNodesUseCaseTests {
    static func sut(
        recentNodesRepository: MockRecentNodesRepository = MockRecentNodesRepository(),
        contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(),
        userUpdateRepository: MockUserUpdateRepository = MockUserUpdateRepository(),
        requestStatesRepository: MockRequestStatesRepository = MockRequestStatesRepository(),
        nodeRepository: MockNodeRepository = MockNodeRepository(),
        hiddenNodesFeatureFlagEnabled: Bool = false
    ) -> RecentNodesUseCase<MockRecentNodesRepository, MockContentConsumptionUserAttributeUseCase, MockUserUpdateRepository, MockRequestStatesRepository, MockNodeRepository> {
        RecentNodesUseCase(
            recentNodesRepository: recentNodesRepository,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            userUpdateRepository: userUpdateRepository,
            requestStatesRepository: requestStatesRepository,
            nodeRepository: nodeRepository,
            hiddenNodesFeatureFlagEnabled: { hiddenNodesFeatureFlagEnabled })
    }
}
