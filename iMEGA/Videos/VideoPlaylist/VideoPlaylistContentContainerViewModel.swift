import Combine
import MEGADomain
import Video

@MainActor
final class VideoPlaylistContentContainerViewModel: ObservableObject {
    
    @Published var sortOrder: SortOrderEntity = .defaultAsc
    
    private(set) var cancellables: Set<AnyCancellable> = []
    
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    
    init(sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        
        monitorSortOrderChanged()
    }
    
    private func monitorSortOrderChanged() {
        sortOrderChangedSequence()
            .receive(on: DispatchQueue.main)
            .assign(to: \.sortOrder, on: self)
            .store(in: &cancellables)
    }
    
    private func sortOrderChangedSequence() -> AnyPublisher<SortOrderEntity, Never> {
        let defaultSortOrder = SortOrderEntity.modificationAsc
        return sortOrderPreferenceUseCase.monitorSortOrder(for: . videoPlaylistContent)
            .map { [weak self] sortOrder in
                guard let self else {
                    return defaultSortOrder
                }
                return doesSupport(sortOrder) ? sortOrder : defaultSortOrder
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private func doesSupport(_ sortOrder: SortOrderEntity) -> Bool {
        PlaylistContentSupportedSortOrderPolicy.supportedSortOrders.contains(sortOrder)
    }
    
    func didSelectSortMenu(sortOrder: SortOrderEntity) {
        guard doesSupport(sortOrder) else {
            return
        }
        sortOrderPreferenceUseCase.save(sortOrder: sortOrder, for: .videoPlaylistContent)
    }
}
