import Combine
import ContentLibraries
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
public final class AddToAlbumsViewModel: AlbumListContentViewModelProtocol {
    @Published var isAlbumsLoaded = false
    @Published public var albums = [AlbumCellViewModel]()
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
    private let albumModificationUseCase: any AlbumModificationUseCaseProtocol
    private let addToCollectionRouter: any AddToCollectionRouting
    private let contentLibrariesConfiguration: ContentLibraries.Configuration
    private let albumSelection: AlbumSelection
    
    public init(
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        albumCoverUseCase: some AlbumCoverUseCaseProtocol,
        albumListUseCase: some AlbumListUseCaseProtocol,
        albumModificationUseCase: some AlbumModificationUseCaseProtocol,
        addToCollectionRouter: some AddToCollectionRouting,
        contentLibrariesConfiguration: ContentLibraries.Configuration = ContentLibraries.configuration,
        albumSelection: AlbumSelection = AlbumSelection(mode: .single)
    ) {
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.thumbnailLoader = thumbnailLoader
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.albumCoverUseCase = albumCoverUseCase
        self.albumListUseCase = albumListUseCase
        self.albumModificationUseCase = albumModificationUseCase
        self.addToCollectionRouter = addToCollectionRouter
        self.contentLibrariesConfiguration = contentLibrariesConfiguration
        self.albumSelection = albumSelection
        
        $editMode
            .assign(to: &albumSelection.$editMode)
    }
    
    public func columns(horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
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
    
    public func onCreateAlbumTapped() {
        showCreateAlbumAlert.toggle()
    }
    
    func monitorUserAlbums() async {
        for await userAlbums in await monitorAlbumsUseCase.monitorSortedUserAlbums(
            excludeSensitives: false,
            by: { $0.creationTime ?? Date.distantPast > $1.creationTime ?? Date.distantPast }) {
            
            guard !Task.isCancelled else { break }
            
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
            
            guard !isAlbumsLoaded else { continue }
            isAlbumsLoaded.toggle()
        }
    }
    
    @MainActor
    func alertViewModel() -> TextFieldAlertViewModel {
        let validator = AlbumNameValidator(
            existingAlbumNames: { [weak self] in self?.albums.map(\.album.name) ?? [] }
        )
        return .init(
            title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
            placeholderText: albums.map(\.album.name).newAlbumName(),
            affirmativeButtonTitle: Strings.Localizable.createFolderButton,
            destructiveButtonTitle: Strings.Localizable.cancel,
            action: { [weak self] newAlbumName in
                guard let self, let newAlbumName else { return }
                let albumName = if newAlbumName.isNotEmpty {
                    newAlbumName
                } else {
                    albums.map(\.album.name).newAlbumName()
                }
                Task {
                    _ = try? await albumListUseCase.createUserAlbum(with: albumName)
                }
            },
            validator: validator.create
        )
    }
}

extension AddToAlbumsViewModel: AddItemsToCollectionViewModelProtocol {
    var isAddButtonDisabled: AnyPublisher<Bool, Never> {
        albumSelection.isAlbumSelectedPublisher.map { !$0 }.eraseToAnyPublisher()
    }
    
    var isItemsNotEmptyPublisher: AnyPublisher<Bool, Never> {
        $albums
            .map(\.isNotEmpty)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func addItems(_ photos: [NodeEntity]) {
        guard let album = albumSelection.albums.values.first,
              photos.isNotEmpty else { return }
        
        Task { [albumModificationUseCase, addToCollectionRouter] in
            let result = try await albumModificationUseCase.addPhotosToAlbum(by: album.id, nodes: photos)
            
            let message = Strings.Localizable.Set.AddTo.Snackbar.message(Int(result.success))
                .replacingOccurrences(of: "[A]", with: album.name)
            addToCollectionRouter.showSnackBarOnDismiss(message: message)
        }
    }
}
