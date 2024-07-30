import Combine
import MEGADomain

struct Preview_SortOrderPreferenceUseCase: SortOrderPreferenceUseCaseProtocol {
    
    func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity {
        .creationAsc
    }
    
    func sortOrder(for node: NodeEntity?) -> SortOrderEntity {
        .creationAsc
    }
    
    func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) { }
    
    func save(sortOrder: SortOrderEntity, for node: NodeEntity) { }
    
    func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func monitorSortOrder(for node: NodeEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Empty().eraseToAnyPublisher()
    }
}
