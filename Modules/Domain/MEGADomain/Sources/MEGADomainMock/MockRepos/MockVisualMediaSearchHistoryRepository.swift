import MEGADomain

public struct MockVisualMediaSearchHistoryRepository: VisualMediaSearchHistoryRepositoryProtocol {
    public static var newRepo: MockVisualMediaSearchHistoryRepository {
        MockVisualMediaSearchHistoryRepository()
    }
    
    public enum Invocation: Sendable, Equatable {
        case history
        case add(entry: SearchTextHistoryEntryEntity)
        case delete(entry: SearchTextHistoryEntryEntity)
    }
    private actor State {
        var invocations: [Invocation] = []
        
        func addInvocation(_ invocation: Invocation) {
            invocations.append(invocation)
        }
    }
    private let searchQueryHistory: [SearchTextHistoryEntryEntity]
    private let state = State()
    
    public init(searchQueryHistory: [SearchTextHistoryEntryEntity] = []) {
        self.searchQueryHistory = searchQueryHistory
    }
    
    public func history() async -> [SearchTextHistoryEntryEntity] {
        await state.addInvocation(.history)
        return searchQueryHistory
    }
    
    public func add(entry: SearchTextHistoryEntryEntity) async {
        await state.addInvocation(.add(entry: entry))
    }
    
    public func delete(entry: SearchTextHistoryEntryEntity) async {
        await state.addInvocation(.delete(entry: entry))
    }
}

extension MockVisualMediaSearchHistoryRepository {
    public var invocations: [Invocation] {
        get async {
            await state.invocations
        }
    }
}
