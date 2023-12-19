import Combine
import MEGADomain

public final class MockSortOrderPreferenceUseCase: SortOrderPreferenceUseCaseProtocol {
    
    var sortOrderEntity: SortOrderEntity
    public private(set) var getSortOrderCallCount = 0
    public private(set) var saveSortOrderCallCount = 0
    public private(set) var monitorSortOrderCallCount = 0
    
    public init(sortOrderEntity: SortOrderEntity) {
        self.sortOrderEntity = sortOrderEntity
    }
    
    public func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity {
        getSortOrderCallCount += 1
        return sortOrderEntity
    }
    
    public func sortOrder(for node: NodeEntity?) -> SortOrderEntity {
        sortOrderEntity
    }
    
    public func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) {
        saveSortOrderCallCount += 1
        sortOrderEntity = sortOrder
    }
    
    public func save(sortOrder: SortOrderEntity, for node: NodeEntity) {
        sortOrderEntity = sortOrder
    }
    
    public func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never> {
        monitorSortOrderCallCount += 1
        return Just(sortOrderEntity).eraseToAnyPublisher()
    }
    
    public func monitorSortOrder(for node: NodeEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Just(sortOrderEntity).eraseToAnyPublisher()
    }
}
