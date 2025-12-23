import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI
import Video

@MainActor
final class PlaylistTabViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer {
    let videoPlaylistsViewModel: VideoPlaylistsViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - MediaTabSharedResourceConsumer

    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)?

    // MARK: - Initialization

    init(
        videoPlaylistsViewModel: VideoPlaylistsViewModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting
    ) {
        self.videoPlaylistsViewModel = videoPlaylistsViewModel
        self.videoConfig = videoConfig
        self.router = router
    }
}

// MARK: - MediaTabNavigationBarItemProvider

extension PlaylistTabViewModel: MediaTabNavigationBarItemProvider {
    func navigationBarItems(for editMode: SwiftUI.EditMode) -> [NavigationBarItemViewModel] {
        guard let sharedResourceProvider else { return [] }

        return [
            // Camera upload status button (leading/left)
            MediaNavigationBarItemFactory.cameraUploadStatusButton(
                viewModel: sharedResourceProvider.cameraUploadStatusButtonViewModel
            ),
            // Search button (trailing/right)
            MediaNavigationBarItemFactory.searchButton {
            }
        ]
    }
}

// MARK: - MediaTabNavigationTitleProvider

extension PlaylistTabViewModel: MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> {
        // Playlist tab always shows the same title
        Just(Strings.Localizable.Videos.Tab.Title.playlist).eraseToAnyPublisher()
    }
}
