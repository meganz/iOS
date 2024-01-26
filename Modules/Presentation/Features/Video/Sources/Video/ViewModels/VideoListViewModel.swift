import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift

public final class VideoListViewModel: ObservableObject {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    @Published var videos = [NodeEntity]()
    @Published var uiState = UIState.initial
    @Published var searchedText = ""
    @Published var sortOrderType = SortOrderEntity.defaultAsc
    
    enum UIState {
        case initial
        case empty
        case loaded
        case error
    }
    
    public init(fileSearchUseCase: some FilesSearchUseCaseProtocol, thumbnailUseCase: some ThumbnailUseCaseProtocol) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    @MainActor
    func loadVideos() async {
        do {
            videos = try await fileSearchUseCase.search(
                string: searchedText,
                parent: nil,
                recursive: true,
                supportCancel: false,
                sortOrderType: sortOrderType,
                formatType: .video,
                cancelPreviousSearchIfNeeded: true
            )
            uiState = videos.isEmpty ? .empty : .loaded
        } catch {
            uiState = .error
        }
    }
}
