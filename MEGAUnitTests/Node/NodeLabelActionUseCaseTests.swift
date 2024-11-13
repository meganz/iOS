@testable import MEGA
import MEGASDKRepoMock
import Testing

@Suite(
    "NodeLabelActionUseCase - Verifies correct results of requests",
    .timeLimit(.minutes(1))
)
struct NodeLabelActionUseCaseTests {

    // MARK: - Helpers
    private static func makeSUT(
        labelColors: [NodeLabelColor] = [],
        setNodeLabelColorResult: Result<Void, NodeLabelActionDomainError> = .success,
        resetNodeLabelColorResult: Result<Void, NodeLabelActionDomainError> = .success,
        nodeLabelColorResult: Result<NodeLabelColor, NodeLabelActionDomainError> = .success(.unknown)
    ) -> NodeLabelActionUseCase {
        let mockRepo = MockNodeLabelActionRepository(
            labelColors: labelColors,
            setNodeLabelColorResult: setNodeLabelColorResult,
            resetNodeLabelColorResult: resetNodeLabelColorResult,
            nodeLabelColorResult: nodeLabelColorResult
        )
        return NodeLabelActionUseCase(nodeLabelActionRepository: mockRepo)
    }
    
    private static var randomNodeLabelColor: NodeLabelColor {
        NodeLabelColor.allCases.randomElement() ?? .blue
    }
    
    private static var resultErrorList: [NodeLabelActionDomainError] {
        [
            .nodeNotFound,
            .unsupportedNodeLabelColorFound,
            .sdkError(MockError.failingError.sdkError ?? .internalError("Test"))
        ]
    }
    
    @discardableResult
    private static func expectResult<T>(
        expectedError: NodeLabelActionDomainError?,
        function: (@escaping (Result<T, NodeLabelActionDomainError>) -> Void) -> Void
    ) async -> T? {
        let result = await withCheckedContinuation { continuation in
            function { result in
                continuation.resume(returning: result)
            }
        }
        
        // Nil expectedError expects to have successful request, otherwise, it should throw the error
        if let expectedError {
            #expect(throws: expectedError.self) { try result.get() }
            return nil
        } else {
            #expect(throws: Never.self) { try result.get() }
            return try? result.get()
        }
    }
    
    // MARK: - Tests
    struct NodeLabelColorList {
        @Test("Should return the expected colors")
        func returnCorrectLabelColors() {
            let expectedColors = NodeLabelColor.allCases
            
            let sut = makeSUT(labelColors: expectedColors)
            
            #expect(sut.labelColors == expectedColors)
        }
    }
    
    struct GetNodeLabelColor {
        @Test("Get node label color successfully")
        func shouldSetNodeLabelColorWithSuccessRequest() async throws {
            let expectedColor = randomNodeLabelColor
            let sut = makeSUT(nodeLabelColorResult: .success(expectedColor))
            
            let color = await expectResult(expectedError: nil) { completion in
                sut.nodeLabelColor(forNode: 1, completion: completion)
            }
            
            try #require(color != nil, "Node label color should be returned")
            #expect(color == expectedColor)
        }
        
        @Test(
            "Get node label color with failed result",
            arguments: resultErrorList
        )
        func shouldGetNodeLabelColorWithFailedRequest(error: NodeLabelActionDomainError) async {
            let sut = makeSUT(nodeLabelColorResult: .failure(error))
            
            await expectResult(expectedError: error) { completion in
                sut.nodeLabelColor(forNode: 1, completion: completion)
            }
        }
    }

    struct SetNodeLabelColor {
        @Test("Set node label color successfully")
        func shouldSetNodeLabelColorWithSuccessRequest() async {
            let sut = makeSUT(setNodeLabelColorResult: .success)
            
            await expectResult(expectedError: nil) { completion in
                sut.setNodeLabelColor(randomNodeLabelColor, forNode: 1, completion: completion)
            }
        }
        
        @Test(
            "Set node label color with failed result",
            arguments: resultErrorList
        )
        func shouldSetNodeLabelColorWithFailedRequest(error: NodeLabelActionDomainError) async {
            let sut = makeSUT(setNodeLabelColorResult: .failure(error))
            
            await expectResult(expectedError: error) { completion in
                sut.setNodeLabelColor(randomNodeLabelColor, forNode: 1, completion: completion)
            }
        }
    }
    
    struct ResetNodeLabelColor {
        @Test("Reset node label color successfully")
        func shouldResetNodeLabelColorWithSuccessRequest() async {
            let sut = makeSUT(resetNodeLabelColorResult: .success)
            
            await expectResult(expectedError: nil) { completion in
                sut.resetNodeLabelColor(forNode: 1, completion: completion)
            }
        }
        
        @Test(
            "Reset node label color with failed result",
            arguments: resultErrorList
        )
        func shouldResetNodeLabelColorWithFailedRequest(error: NodeLabelActionDomainError) async {
            let sut = makeSUT(resetNodeLabelColorResult: .failure(error))
            
            await expectResult(expectedError: error) { completion in
                sut.resetNodeLabelColor(forNode: 1, completion: completion)
            }
        }
    }
}

 extension NodeLabelActionDomainError: @retroactive Equatable {
    public static func == (lhs: NodeLabelActionDomainError, rhs: NodeLabelActionDomainError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
 }
