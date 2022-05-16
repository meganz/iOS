import Combine
import SwiftUI

@available(iOS 14.0, *)
final class AlbumLibraryContentViewModel: NSObject, ObservableObject  {
    var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 10),
        count: 3
    )
    
    @Published var albums: [NodeEntity] = []
    @Published var selectedAlbum: NodeEntity?
    
    private var loadingTask: Task<Void, Never>?
    private var usecase: AlbumUseCaseProtocol
    
    init(usecase: AlbumUseCaseProtocol) {
        self.usecase = usecase
    }
    
    @MainActor
    func loadAlbums() {
        loadingTask = Task {
            do {
                albums = try await usecase.loadAlbums()
            } catch {}
        }
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
}
