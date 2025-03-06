import Combine
import MEGADomain

public final class MockSortOrderPreferenceUseCase: SortOrderPreferenceUseCaseProtocol {
    
    var sortOrderEntity: SortOrderEntity
    public private(set) var getSortOrderCallCount = 0
    public private(set) var saveSortOrderCallCount = 0
    public private(set) var monitorSortOrderCallCount = 0
    
    public var messages = [Message]()
    
    public init(sortOrderEntity: SortOrderEntity = .none) {
        self.sortOrderEntity = sortOrderEntity
    }
    
    public func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity {
        getSortOrderCallCount += 1
        messages.append(.sortOrder(key: key))
        return sortOrderEntity
    }
    
    public func sortOrder(for node: NodeEntity?) -> SortOrderEntity {
        sortOrderEntity
    }
    
    public func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) {
        saveSortOrderCallCount += 1
        sortOrderEntity = sortOrder
        messages.append(.save(sortOrder: sortOrder, for: key))
    }
    
    public func save(sortOrder: SortOrderEntity, for node: NodeEntity) {
        sortOrderEntity = sortOrder
    }
    
    public func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never> {
        monitorSortOrderCallCount += 1
        messages.append(.monitorSortOrder(key: key))
        return Just(sortOrderEntity).eraseToAnyPublisher()
    }
    
    public func monitorSortOrder(for node: NodeEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Just(sortOrderEntity).eraseToAnyPublisher()
    }
}

extension MockSortOrderPreferenceUseCase {
    
    // MARK: nested type
    
    public enum Message: Equatable {
        case save(sortOrder: SortOrderEntity, for: SortOrderPreferenceKeyEntity)
        case sortOrder(key: SortOrderPreferenceKeyEntity)
        case monitorSortOrder(key: SortOrderPreferenceKeyEntity)
    }
}
