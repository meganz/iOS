import MEGADomain

public struct MockVisualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCaseProtocol {
    public enum Invocation: Equatable, Sendable {
        case history
        case add(entry: SearchTextHistoryEntryEntity)
    }
    private actor State {
        var invocations: [Invocation] = []
        
        func addInvocation(_ invocation: Invocation) {
            invocations.append(invocation)
        }
    }
    private let state = State()
    private let searchQueryHistoryEntries: [SearchTextHistoryEntryEntity]
    
    public init(
        searchQueryHistoryEntries: [SearchTextHistoryEntryEntity] = []
    ) {
        self.searchQueryHistoryEntries = searchQueryHistoryEntries
    }
    
    public func history() async -> [SearchTextHistoryEntryEntity] {
        await state.addInvocation(.history)
        return searchQueryHistoryEntries.sorted { $0.searchDate > $1.searchDate }
    }
    
    public func add(entry: SearchTextHistoryEntryEntity) async {
        await state.addInvocation(.add(entry: entry))
    }
}

extension MockVisualMediaSearchHistoryUseCase {
    public var invocations: [Invocation] {
        get async {
            await state.invocations
        }
    }
}
