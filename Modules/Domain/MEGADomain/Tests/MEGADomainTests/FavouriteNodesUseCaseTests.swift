import MEGADomain
import MEGADomainMock
import XCTest

final class FavouriteNodesUseCaseTests: XCTestCase {

    let favouriteNodesSuccessRepository = MockFavouriteNodesRepository(result: .success([]))
    let favouriteNodesFailureRepository = MockFavouriteNodesRepository(result: .failure(.generic))
        
    func testAllFavouriteNodes() async throws {
        let resultNodes = [NodeEntity]()
        let nodes = try await favouriteNodesSuccessRepository.allFavouritesNodes(limit: 0)
        XCTAssertEqual(nodes, resultNodes)
    }
    
    func testAllFavouriteNodesSearchWithSensitiveFlag_returnsCorrectNodes() async throws {
        let sensitiveNode = NodeEntity(handle: 2)

        let nodes: [NodeEntity: Result<Bool, any Error>] = [
            .init(handle: 1): .success(false),
            sensitiveNode: .success(true),
            .init(handle: 3): .success(false)
        ]
        
        let scenarios: [(Bool, [NodeEntity])] = [
            (true, nodes.keys.filter { $0 != sensitiveNode }),
            (false, nodes.keys.map { $0 })
        ]
        
        for (excludeSensitives, expectedResult) in scenarios {
            let sut = sut(
                repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
                nodeRepository: MockNodeRepository(isInheritingSensitivityResults: nodes)
            )
            
            let result = try await sut.allFavouriteNodes(searchString: nil, excludeSensitives: excludeSensitives, limit: 0)
            
            XCTAssertEqual(result, expectedResult)
        }
    }
    
    func testAllFavouriteNodesSearchWithSensitiveFlagAndLimitSet_returnsCorrectAmountNodes() async throws {
        let sensitiveNode = NodeEntity(handle: 2)
        let sensitiveNode2 = NodeEntity(handle: 4)
        let expectedResult = NodeEntity(handle: 3)
        
        let nodes: [NodeEntity: Result<Bool, any Error>] = [
            sensitiveNode: .success(true),
            sensitiveNode2: .success(true),
            expectedResult: .success(false)
        ]
        
        let sut = sut(
            repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
            nodeRepository: MockNodeRepository(isInheritingSensitivityResults: nodes)
        )
        
        let result = try await sut.allFavouriteNodes(searchString: nil, excludeSensitives: true, limit: 1)
        
        XCTAssertEqual(result, [expectedResult])
    }
    
    func testAllFavouriteNodesSearch_whenExcludeSensitiveNodesTrue_returnsNoSensitveNodes() async throws {
        let sensitiveNode = NodeEntity(handle: 2)
        let nodes: [NodeEntity: Result<Bool, any Error>] = [
            .init(handle: 1): .success(false),
            sensitiveNode: .success(true),
            .init(handle: 3): .success(false)
        ]
        
        let sut = sut(
            repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResults: nodes),
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(
                excludeSensitives: true)
        )
        
        let result = try await sut.allFavouriteNodes(searchString: nil)
        
        XCTAssertEqual(result, nodes.keys.filter {$0 != sensitiveNode })
    }
    
    func testAllFavouriteNodesSearch_whenExcludeSensitiveNodesFalse_returnsAllNodesIncludingSensitive() async throws {
        let sensitiveNode = NodeEntity(handle: 2)
        let nodes: [NodeEntity: Result<Bool, any Error>] = [
            .init(handle: 1): .success(false),
            sensitiveNode: .success(true),
            .init(handle: 3): .success(false)
        ]
        
        let sut = sut(
            repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResults: nodes),
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(
                excludeSensitives: false)
        )
        
        let result = try await sut.allFavouriteNodes(searchString: nil)
        
        XCTAssertEqual(result, nodes.keys.map { $0 })
    }
}

extension FavouriteNodesUseCaseTests {
    
    private func sut(
        repo: some FavouriteNodesRepositoryProtocol = MockFavouriteNodesRepository(),
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase()
    ) -> some FavouriteNodesUseCaseProtocol {
        FavouriteNodesUseCase(
            repo: repo,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase)
    }
}
