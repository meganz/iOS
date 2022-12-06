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
    
    var loadingTask: Task<Void, Never>?
    var albumLoadingTask: Task<Void, Never>?
    private var usecase: AlbumListUseCaseProtocol
    
    init(usecase: AlbumListUseCaseProtocol) {
        self.usecase = usecase
    }
    
    @MainActor
    func loadAlbums() {
        loadFavouriteAlbum()
        loadOtherAlbums()
        
        usecase.startMonitoringNodesUpdate { [weak self] in
            self?.loadOtherAlbums()
        }
    }
    
    func cancelLoading() {
        cancelFavouriteAlbumLoading()
        cancelOtherAlbumsLoading()
    }
    
    // MARK: - Private
    @MainActor
    private func loadFavouriteAlbum() {
        loadingTask = Task {
            do {
                cameraUploadNode = try await usecase.loadCameraUploadNode()
            } catch {}
            
            shouldLoad = false
        }
    }
    
    @MainActor
    private func loadOtherAlbums() {
        albumLoadingTask = Task {
            do {
                albums = try await usecase.loadAlbums().map { album in
                    album.update(name: localisedName(forAlbum: album))
                }
            } catch {}
        }
    }
    
    private func localisedName(forAlbum album: AlbumEntity) -> String {
        if album.type == .gif { return Strings.Localizable.CameraUploads.Albums.Gif.title }
        else if album.type == .raw { return Strings.Localizable.CameraUploads.Albums.Raw.title }
        return ""
    }
    
    private func cancelFavouriteAlbumLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    private func cancelOtherAlbumsLoading() {
        usecase.stopMonitoringNodesUpdate()
        albumLoadingTask?.cancel()
        albumLoadingTask = nil
    }
}
