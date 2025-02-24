@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import Search
import Testing

@Suite("RecentActionBucketProvider Tests")
struct RecentActionBucketProviderTests {
    
    struct MockNodeIconUsecase: NodeIconUsecaseProtocol {
        func iconData(for node: MEGADomain.NodeEntity) -> Data {
            Data()
        }
    }
    
    actor Harness {
        let sut: RecentActionBucketProvider
        let mapper = SearchResultMapper(
            sdk: MockSdk(),
            nodeIconUsecase: MockNodeIconUsecase(),
            nodeDetailUseCase: MockNodeDetailUseCase(),
            nodeUseCase: MockNodeUseCase(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            mediaUseCase: MockMediaUseCase(),
            nodeActions: .mock(),
            hiddenNodesFeatureEnabled: false
        )
        init(results: [String] = []) {
            sut = RecentActionBucketProvider(
                sdk: MockSdk(),
                bucket: MockRecentActionBucketTrampoline(nodes: results.mappedAsNodes),
                mapper: mapper,
                nodeUseCase: MockNodeUseCase(),
                nodeUpdateRepository: MockNodeUpdateRepository(),
                sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(excludeSensitives: false)
            )
        }
    }

    @Test("initial search with no results")
    func initialSearch() async throws {
        let harness = Harness()
        let resultsEntity = try #require(await harness.sut.search(queryRequest: .initial, lastItemIndex: nil))
        #expect(resultsEntity.results == [])
    }
    
    @Test("initial search with some results")
    func initialSearchWithResults() async throws {
        let harness = Harness(results: ["1", "2", "3"])
        let resultsEntity = try #require(await harness.sut.search(queryRequest: .initial, lastItemIndex: nil))
        #expect(resultsEntity.results.map(\.title) == ["1", "2", "3"])
    }
    
    @Test("initial search returns no chips")
    func initialSearchNoChips() async throws {
        let harness = Harness(results: ["1", "2", "3"])
        let resultsEntity = try #require(await harness.sut.search(queryRequest: .initial, lastItemIndex: nil))
        #expect(resultsEntity.appliedChips.isEmpty)
        #expect(resultsEntity.availableChips.isEmpty)
    }
    
    @Test("search with last index returns nil")
    func searchWithLastItemIndex() async throws {
        let harness = Harness(results: ["1", "2", "3"])
        let resultsEntity = try #require(
            await harness.sut.search(
                queryRequest: .userSupplied(
                    .init(
                        query: "",
                        sorting: .oldest,
                        mode: .home,
                        isSearchActive: false,
                        chips: []
                    )
                ),
                lastItemIndex: 1
            )
        )
        #expect(resultsEntity == .testEmpty)
    }
}

extension [String] {
    var mappedAsNodes: [NodeEntity] {
        map {
            .testNodeForRecentBucket($0)
        }
    }
}

extension NodeEntity {
    static func testNodeForRecentBucket(_ nameIdx: String) -> NodeEntity {
        .init(
            name: nameIdx,
            handle: HandleEntity(Int(nameIdx) ?? 0)
        )
    }
}

extension SearchResultsEntity {
    static let testEmpty = SearchResultsEntity(
        results: [],
        availableChips: [],
        appliedChips: []
    )
}

extension SearchResultsEntity: @retroactive Equatable {
    public static func == (lhs: SearchResultsEntity, rhs: SearchResultsEntity) -> Bool {
        guard
            lhs.results == rhs.results,
            lhs.appliedChips == rhs.appliedChips,
            lhs.availableChips == rhs.availableChips
        else {
            return false
        }
        return true
    }
    
}
