import ContentLibraries
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import SwiftUI

@MainActor
final class AddToAlbumsViewModel: AlbumListContentViewModelProtocol {
    @Published var albums = [AlbumCellViewModel]()
    @Published var editMode: EditMode = .active
    public let createButtonOpacity: Double = 1.0
    
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    private let contentLibrariesConfiguration: ContentLibraries.Configuration
    
    private let albumSelection = AlbumSelection(mode: .single)
    
    init(
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        albumCoverUseCase: some AlbumCoverUseCaseProtocol,
        contentLibrariesConfiguration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.thumbnailLoader = thumbnailLoader
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.contentLibrariesConfiguration = contentLibrariesConfiguration
        
        $editMode
            .assign(to: &albumSelection.$editMode)
    }
    
    func columns(horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        let count = if let horizontalSizeClass {
            horizontalSizeClass == .compact  ? 3 : 5
        } else {
            3
        }
        return Array(
            repeating: .init(.flexible(), spacing: 10),
            count: count
        )
    }
    
    func monitorUserAlbums() async {
        for await userAlbums in await monitorAlbumsUseCase.monitorSortedUserAlbums(
            excludeSensitives: false,
            by: { $0.creationTime ?? Date.distantPast > $1.creationTime ?? Date.distantPast }) {
            
            guard !Task.isCancelled else { return }
            
            albums = userAlbums
                .compactMap { [weak self] album -> AlbumCellViewModel? in
                    guard let self else { return nil }
                    return AlbumCellViewModel(
                        thumbnailLoader: thumbnailLoader,
                        monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
                        nodeUseCase: nodeUseCase,
                        sensitiveNodeUseCase: sensitiveNodeUseCase,
                        sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                        albumCoverUseCase: albumCoverUseCase,
                        album: album,
                        selection: albumSelection,
                        configuration: contentLibrariesConfiguration
                    )
                }
        }
    }
    
    func onCreateAlbumTapped() {
        // CC-8484: Handle create album alert with validation
    }
}
