import MEGADomain
import MEGAPresentation

final class VideoListViewModel: ViewModelType {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    
    var invokeCommand: ((Command) -> Void)?
    
    enum Action: ActionType {
        case onViewAppeared(searchedText: String?, sortOrderType: SortOrderEntity)
    }
    
    enum Command: CommandType, Equatable {
        case showErrorView
        case showEmptyItemView
        case showItems(nodes: [NodeEntity])
        case updateItems(nodes: [NodeEntity])
    }
    
    init(fileSearchUseCase: some FilesSearchUseCaseProtocol) {
        self.fileSearchUseCase = fileSearchUseCase
    }
    
    func dispatch(_ action: Action) {
        switch action {
        case .onViewAppeared(let searchedText, let sortOrderType):
            searchVideos(for: searchedText, order: sortOrderType)
            listenNodesUpdate()
        }
    }
    
    private func searchVideos(for searchedText: String?, order sortOrderType: SortOrderEntity) {
        fileSearchUseCase.search(
            string: searchedText,
            parent: nil,
            recursive: true,
            supportCancel: false,
            sortOrderType: sortOrderType,
            cancelPreviousSearchIfNeeded: true
        ) { [weak self] videos, isFail in
            guard !isFail else {
                self?.invokeCommand?(.showErrorView)
                return
            }
            
            guard let videos else {
                self?.invokeCommand?(.showEmptyItemView)
                return
            }
            self?.invokeCommand?(.showItems(nodes: videos))
        }
    }
    
    private func listenNodesUpdate() {
        fileSearchUseCase.onNodesUpdate { [weak self] nodes in
            let updatedVideos = nodes.filter { $0.mediaType == .video }
            guard updatedVideos.isNotEmpty else { return }
            self?.invokeCommand?(.updateItems(nodes: updatedVideos))
        }
    }
}
