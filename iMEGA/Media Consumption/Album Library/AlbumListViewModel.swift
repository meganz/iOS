import Combine
import SwiftUI
import MEGADomain

final class AlbumListViewModel: NSObject, ObservableObject  {
    var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 10),
        count: 3
    )
    
    @Published var cameraUploadNode: NodeEntity?
    @Published var album: AlbumEntity?
    @Published var shouldLoad = true
    @Published var albums = [AlbumEntity]()
    @Published var showCreateAlbumAlert = false
    
    var albumLoadingTask: Task<Void, Never>?
    private let usecase: AlbumListUseCaseProtocol
    
    var isCreateAlbumFeatureFlagEnabled: Bool {
        FeatureFlagProvider().isFeatureFlagEnabled(for: .createAlbum)
    }
    
    init(usecase: AlbumListUseCaseProtocol) {
        self.usecase = usecase
    }
    
    @MainActor
    func loadAlbums() {
        loadAllAlbums()
        usecase.startMonitoringNodesUpdate { [weak self] in
            self?.loadAllAlbums()
        }
    }
    
    func cancelLoading() {
        usecase.stopMonitoringNodesUpdate()
        albumLoadingTask?.cancel()
    }
    
    // MARK: - Private
    
    @MainActor
    private func loadAllAlbums() {
        albumLoadingTask = Task {
            albums = await usecase.loadAlbums().map({ album in
                if let localizedAlbumName = localisedName(forAlbumType: album.type) {
                    return album.update(name: localizedAlbumName)
                }
                return album
            })
            shouldLoad = false
        }
    }
    
    private func localisedName(forAlbumType albumType: AlbumEntityType) -> String? {
        switch (albumType) {
        case .favourite:
            return Strings.Localizable.CameraUploads.Albums.Favourites.title
        case .gif:
            return Strings.Localizable.CameraUploads.Albums.Gif.title
        case .raw:
            return Strings.Localizable.CameraUploads.Albums.Raw.title
        default:
            return nil
        }
    }
    
    @MainActor
    func createUserAlbum(with name: String?) {
        guard let name = name, !name.isEmpty else { return }
        shouldLoad = true
        Task {
            do {
                let newAlbum = try await usecase.createUserAlbum(with: name)
                self.albums.append(newAlbum)
                self.albums.sort(by: { $0.name < $1.name })
            } catch {
                MEGALogError("Error creating album: \(error.localizedDescription)")
            }
            shouldLoad = false
        }
    }
}
