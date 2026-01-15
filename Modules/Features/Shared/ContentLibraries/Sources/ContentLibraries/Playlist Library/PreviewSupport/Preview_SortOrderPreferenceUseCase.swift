import Combine
import MEGADomain

struct Preview_SortOrderPreferenceUseCase: SortOrderPreferenceUseCaseProtocol {
    
    func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity {
        .creationAsc
    }
    
    func sortOrder(for nodeHandle: HandleEntity?) -> SortOrderEntity {
        .creationAsc
    }
    
    func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) { }
    
    func save(sortOrder: SortOrderEntity, for nodeHandle: HandleEntity) { }
    
    func monitorSortOrder(for key: SortOrderPreferenceKeyEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func monitorSortOrder(for nodeHandle: HandleEntity) -> AnyPublisher<SortOrderEntity, Never> {
        Empty().eraseToAnyPublisher()
    }
}
