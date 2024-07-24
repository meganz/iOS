import Combine
import MEGADomain
import SwiftUI

@MainActor
final class AlbumCoverPickerViewModel: ObservableObject {
    
    @Published var photos = [AlbumPhotoEntity]()
    @Published var isSaveButtonDisabled = true
    @Published var isDismiss = false
    
    let photoSelection = AlbumCoverPickerPhotoSelection()
    let router: any AlbumContentRouting
    
    private let album: AlbumEntity
    private let albumContentsUseCase: any AlbumContentsUseCaseProtocol
    private let completion: (AlbumEntity, AlbumPhotoEntity) -> Void
    private var subscriptions = Set<AnyCancellable>()
    var loadingTask: Task<Void, Never>?
    
    init(album: AlbumEntity,
         albumContentsUseCase: any AlbumContentsUseCaseProtocol,
         router: some AlbumContentRouting,
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
    
    private func loadNodes() async {
        do {
            photos = try await albumContentsUseCase.latestModifiedPhotos(in: album)
            await selectCoverNode()
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
        }
    }
    
    private func selectCoverNode() async {
        photoSelection.selectedPhoto = await albumContentsUseCase.selectCoverNode(photos: photos, album: album)
    }
}
