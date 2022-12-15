import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain

final class AlbumCellViewModel: ObservableObject {
    @Published var numberOfNodes = 0
    @Published var thumbnailContainer: any ImageContaining
    @Published var isLoading: Bool = false
    @Published var title: String = ""
    
    private let album: AlbumEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    private var loadingTask: Task<Void, Never>?
    
    init(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        album: AlbumEntity
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.album = album
        
        title = album.name
        numberOfNodes = album.count
        thumbnailContainer = ImageContainer(image: Image(Asset.Images.Album.placeholder.name), isPlaceholder: true)
    }
    
    func loadAlbumInfo() {
        guard let coverNode = album.coverNode else {
            return
        }
        if !isLoading {
            isLoading.toggle()
        }
        loadingTask = Task {
            await loadThumbnail(for: coverNode)
        }
    }
    
    func cancelLoading() {
        isLoading = false
        loadingTask?.cancel()
    }
    
    // MARK: Private
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let imageContainer = try? await thumbnailUseCase.loadThumbnailContainer(for: node, type: .thumbnail) else {
            isLoading = false
            return
        }
        
        thumbnailContainer = imageContainer
        isLoading = false
    }
}
