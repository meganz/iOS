import MEGADomain

public struct MockVisualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCaseProtocol {
    public enum Invocations: Equatable, Sendable {
        case searchQueryHistory
        case save(entries: [SearchTextHistoryEntryEntity])
    }
    private actor State {
        var invocations: [Invocations] = []
        
        func addInvocation(_ invocation: Invocations) {
            invocations.append(invocation)
        }
    }
    private let state = State()
    private let searchQueryHistoryResult: Result<[SearchTextHistoryEntryEntity], any Error>
    private let storeEntityResult: Result<Void, any Error>
    
    public init(
        searchQueryHistoryResult: Result<[SearchTextHistoryEntryEntity], any Error> = .failure(GenericErrorEntity()),
        storeEntityResult: Result<Void, any Error> = .failure(GenericErrorEntity())
    ) {
        self.searchQueryHistoryResult = searchQueryHistoryResult
        self.storeEntityResult = storeEntityResult
    }
    
    public func searchQueryHistory() async throws -> [SearchTextHistoryEntryEntity] {
        await state.addInvocation(.searchQueryHistory)
        return try await withCheckedThrowingContinuation {
            $0.resume(with: searchQueryHistoryResult)
        }
    }
    
    public func save(entries: [SearchTextHistoryEntryEntity]) async throws {
        await state.addInvocation(.save(entries: entries))
        return try await withCheckedThrowingContinuation {
            $0.resume(with: storeEntityResult)
        }
    }
}

extension MockVisualMediaSearchHistoryUseCase {
    public var invocations: [Invocations] {
        get async {
            await state.invocations
        }
    }
}
