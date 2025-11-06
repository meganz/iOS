import Combine
import MEGAAppPresentation
import MEGADomain

@MainActor
public protocol VideoPlaylistsContentViewModelProtocol: ObservableObject {
    var videoPlaylists: [VideoPlaylistEntity] { get }
    var thumbnailLoader: any ThumbnailLoaderProtocol { get }
    var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol { get }
    var sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol { get }
    var setSelection: SetSelection { get }
}
