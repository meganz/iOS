import ContentLibraries
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
final class AddToAlbumsViewModel: AlbumListContentViewModelProtocol {
    @Published var albums = [AlbumCellViewModel]()
    @Published var editMode: EditMode = .active
    @Published var showCreateAlbumAlert = false
    @Published var newAlbumName = ""
    public let createButtonOpacity: Double = 1.0
    
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumCoverUseCase: any AlbumCoverUseCaseProtocol
    private let albumListUseCase: any AlbumListUseCaseProtocol
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
        albumListUseCase: some AlbumListUseCaseProtocol,
        contentLibrariesConfiguration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.thumbnailLoader = thumbnailLoader
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.albumListUseCase = albumListUseCase
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
        showCreateAlbumAlert.toggle()
    }
    
    func alertViewModel() -> TextFieldAlertViewModel {
        .init(
            title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
            placeholderText: albums.map(\.album.name).newAlbumName(),
            affirmativeButtonTitle: Strings.Localizable.createFolderButton,
            destructiveButtonTitle: Strings.Localizable.cancel,
            action: { [weak self] newAlbumName in
                guard let self else { return }
                let albumName = if let newAlbumName, newAlbumName.isNotEmpty {
                    newAlbumName
                } else {
                    albums.map(\.album.name).newAlbumName()
                }
                Task {
                    _ = try? await albumListUseCase.createUserAlbum(with: albumName)
                }
            },
            validator: AlbumNameValidator(
                existingAlbumNames: { [weak self] in self?.albums.map(\.album.name) ?? [] }).create
        )
    }
}
