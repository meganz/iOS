import MEGADomain
import MEGADomainMock
import XCTest

final class FavouriteNodesUseCaseTests: XCTestCase {

    let favouriteNodesSuccessRepository = MockFavouriteNodesRepository(result: .success([]))
    let favouriteNodesFailureRepository = MockFavouriteNodesRepository(result: .failure(.generic))
    
    func testGetAllFavouriteNodes_success() {
        favouriteNodesSuccessRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testGetAllFavouriteNodes_failed() {
        let mockError: GetFavouriteNodesErrorEntity = .generic
        favouriteNodesFailureRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testGetFavouriteNodesWithLimitCount_success() {
        favouriteNodesSuccessRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testGetFavouriteNodesWithLimitCount_failed() {
        let mockError: GetFavouriteNodesErrorEntity = .generic
        favouriteNodesFailureRepository.getAllFavouriteNodes { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testAllFavouriteNodesWithSearchStringValue_success() {
        favouriteNodesSuccessRepository.allFavouriteNodes(searchString: "test") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testAllFavouriteNodesWithNilSearchStringValue_success() {
        favouriteNodesSuccessRepository.allFavouriteNodes(searchString: nil) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected")
            }
        }
    }
    
    func testAllFavouriteNodesWithSearchStringValue_failed() {
        let searchString = "test"
        favouriteNodesFailureRepository.allFavouriteNodes(searchString: searchString) { result in
            switch result {
            case .success:
                XCTFail("errors are not expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testAllFavouriteNodesWithNilSearchStringValue_failed() {
        favouriteNodesFailureRepository.allFavouriteNodes(searchString: nil) { result in
            switch result {
            case .success:
                XCTFail("errors are not expected")
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
    
    func testAllFavouriteNodes() async throws {
        let resultNodes = [NodeEntity]()
        let nodes = try await favouriteNodesSuccessRepository.allFavouritesNodes(limit: 0)
        XCTAssertEqual(nodes, resultNodes)
    }
    
    func testAllFavouriteNodesSearchWithSensitiveFlag_returnsCorrectNodes() async throws {
        let sensitiveNode = NodeEntity(handle: 2)

        let nodes: [NodeEntity: Result<Bool, Error>] = [
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
        
        let nodes: [NodeEntity: Result<Bool, Error>] = [
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
    
    func testAllFavouriteNodesSearch_whenFeatureFlagIsOff_returnsAllNodesIncludingSensitive() async throws {
        let sensitiveNode = NodeEntity(handle: 2)
        let nodes: [NodeEntity: Result<Bool, Error>] = [
            .init(handle: 1): .success(false),
            sensitiveNode: .success(true),
            .init(handle: 3): .success(false)
        ]
        
        let sut = sut(
            repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResults: nodes),
            contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(
                sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false)),
            hiddenNodesFeatureFlagEnabled: false
        )
        
        let result = try await sut.allFavouriteNodes(searchString: nil)
        
        XCTAssertEqual(result, nodes.keys.map { $0 })
    }
    
    func testAllFavouriteNodesSearch_whenShowHiddenNodesFalse_returnsNoSensitveNodes() async throws {
        let sensitiveNode = NodeEntity(handle: 2)
        let nodes: [NodeEntity: Result<Bool, Error>] = [
            .init(handle: 1): .success(false),
            sensitiveNode: .success(true),
            .init(handle: 3): .success(false)
        ]
        
        let sut = sut(
            repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResults: nodes),
            contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(
                sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false)),
            hiddenNodesFeatureFlagEnabled: true
        )
        
        let result = try await sut.allFavouriteNodes(searchString: nil)
        
        XCTAssertEqual(result, nodes.keys.filter {$0 != sensitiveNode })
    }
    
    func testAllFavouriteNodesSearch_whenShowHiddenNodesTrue_returnsAllNodesIncludingSensitive() async throws {
        let sensitiveNode = NodeEntity(handle: 2)
        let nodes: [NodeEntity: Result<Bool, Error>] = [
            .init(handle: 1): .success(false),
            sensitiveNode: .success(true),
            .init(handle: 3): .success(false)
        ]
        
        let sut = sut(
            repo: MockFavouriteNodesRepository(result: .success(nodes.keys.map { $0 })),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResults: nodes),
            contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(
                sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: true)),
            hiddenNodesFeatureFlagEnabled: true
        )
        
        let result = try await sut.allFavouriteNodes(searchString: nil)
        
        XCTAssertEqual(result, nodes.keys.map { $0 })
    }
}

extension FavouriteNodesUseCaseTests {
    
    private func sut(
        repo: some FavouriteNodesRepositoryProtocol = MockFavouriteNodesRepository(),
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        hiddenNodesFeatureFlagEnabled: Bool = false) -> some FavouriteNodesUseCaseProtocol {
        FavouriteNodesUseCase(
            repo: repo,
            nodeRepository: nodeRepository,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { hiddenNodesFeatureFlagEnabled })
    }
}
