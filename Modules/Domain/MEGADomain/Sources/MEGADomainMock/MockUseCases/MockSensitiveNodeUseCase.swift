import AsyncAlgorithms
import MEGADomain
import MEGASwift

public final class MockSensitiveNodeUseCase: SensitiveNodeUseCaseProtocol {
    
    private let isInheritingSensitivityResult: Result<Bool, Error>
    private let isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>]
    private let monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error>
    private let sensitivityChangesForNode: AnyAsyncSequence<Bool>
    
    public init(isInheritingSensitivityResult: Result<Bool, Error> = .failure(GenericErrorEntity()),
                isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>] = [:],
                monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence(),
                sensitivityChangesForNode: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.isInheritingSensitivityResult = isInheritingSensitivityResult
        self.isInheritingSensitivityResults = isInheritingSensitivityResults
        self.monitorInheritedSensitivityForNode = monitorInheritedSensitivityForNode
        self.sensitivityChangesForNode = sensitivityChangesForNode
    }
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        try await withCheckedThrowingContinuation {
            $0.resume(with: isInheritingSensitivityResult(for: node))
        }
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        switch isInheritingSensitivityResult(for: node) {
        case .success(let isSensitive):
           isSensitive
        case .failure(let error):
            throw error
        }
    }
    
    public func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        monitorInheritedSensitivityForNode
    }
    
    public func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        sensitivityChangesForNode
    }

    public func mergeInheritedAndDirectSensitivityChanges(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        merge(
            sensitivityChanges(for: node),
            monitorInheritedSensitivity(for: node)
        ).eraseToAnyAsyncThrowingSequence()
    }
}

// MARK: - Private Helpers
extension MockSensitiveNodeUseCase {
    private func isInheritingSensitivityResult(for node: NodeEntity) -> Result<Bool, Error> {
        isInheritingSensitivityResults[node.handle] ?? isInheritingSensitivityResult
    }
}
