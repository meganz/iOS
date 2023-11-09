import Combine
import MEGADomain

public final class MockSortOrderPreferenceUseCase: SortOrderPreferenceUseCaseProtocol {
    
    var sortOrderEntity: SortOrderEntity
    
    public init(sortOrderEntity: SortOrderEntity) {
        self.sortOrderEntity = sortOrderEntity
    }
    
    public func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity {
        sortOrderEntity
    }
    
    public func sortOrder(for node: NodeEntity?) -> SortOrderEntity {
        sortOrderEntity
    }
    
    public func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) {
        sortOrderEntity = sortOrder
    }
    
    public func save(sortOrder: SortOrderEntity, for node: NodeEntity) {
        sortOrderEntity = sortOrder
    }
    
    public func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Just(sortOrderEntity).eraseToAnyPublisher()
    }
    
    public func monitorSortOrder(for node: NodeEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Just(sortOrderEntity).eraseToAnyPublisher()
    }
}
