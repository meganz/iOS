import SwiftUI
import Combine
import MEGADomain

final class AlbumCoverPickerViewModel: ObservableObject {
    
    @Published var photos = [AlbumPhotoEntity]()
    @Published var isSaveButtonDisabled = true
    @Published var isDismiss = false
    
    let photoSelection = AlbumCoverPickerPhotoSelection()
    let router: AlbumContentRouting
    
    private let album: AlbumEntity
    private let albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let completion: (AlbumEntity, AlbumPhotoEntity) -> Void
    private var subscriptions = Set<AnyCancellable>()
    var loadingTask: Task<Void, Never>?
    
    init(album: AlbumEntity,
         albumContentsUseCase: AlbumContentsUseCaseProtocol,
         router: AlbumContentRouting,
         completion: @escaping (AlbumEntity, AlbumPhotoEntity) -> Void) {
        self.album = album
        self.albumContentsUseCase = albumContentsUseCase
        self.router = router
        self.completion = completion
        
        setupSubscriptions()
    }
    
    deinit {
        loadingTask?.cancel()
    }
    
    func columns(horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        Array(
            repeating: .init(.flexible(), spacing: 4),
            count: horizontalSizeClass == .compact ? 3 : 5
        )
    }
    
    func loadAlbumContents() {
        loadingTask = Task {
            await loadNodes()
        }
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
    }
    
    func onSave() {
        guard let newCoverNode = photoSelection.selectedPhoto else { return }
        completion(album, newCoverNode)
        isDismiss.toggle()
    }
    
    func onCancel() {
        isDismiss.toggle()
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        photoSelection.$selectedPhoto
            .dropFirst(2)
            .sink { [weak self] selectedPhoto in
                if self?.album.coverNode != selectedPhoto?.photo {
                    self?.isSaveButtonDisabled = false
                }
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    private func loadNodes() async {
        do {
            photos = try await albumContentsUseCase.photos(in: album)
            photos.sort {
                $0.photo.modificationTime > $1.photo.modificationTime
            }
            selectCoverNode()
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
        }
    }
    
    private func selectCoverNode() {
        if let coverNode = album.coverNode,
           let coverPhoto = photos.first(where: { $0.id == coverNode.handle } ) {
            photoSelection.selectedPhoto = coverPhoto
        } else {
            photoSelection.selectedPhoto = photos.first
        }
    }
}
