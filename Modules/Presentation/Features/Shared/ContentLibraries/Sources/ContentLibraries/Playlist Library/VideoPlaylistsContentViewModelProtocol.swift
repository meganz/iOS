import Combine
import MEGADomain
import MEGAPresentation

public protocol VideoPlaylistsContentViewModelProtocol: ObservableObject {
    var videoPlaylists: [VideoPlaylistEntity] { get }
    var thumbnailLoader: any ThumbnailLoaderProtocol { get }
    var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol { get }
    var sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol { get }
}
