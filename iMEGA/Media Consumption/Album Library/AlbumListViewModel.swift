import Combine
import SwiftUI
import MEGADomain

@available(iOS 14.0, *)
final class AlbumListViewModel: NSObject, ObservableObject  {
    var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 10),
        count: 3
    )
    
    @Published var cameraUploadNode: NodeEntity?
    @Published var shouldLoad = true
    
    private var loadingTask: Task<Void, Never>?
    private var usecase: AlbumListUseCaseProtocol
    
    init(usecase: AlbumListUseCaseProtocol) {
        self.usecase = usecase
    }
    
    @MainActor
    func loadCameraUploadNode() {
        loadingTask = Task {
            do {
                cameraUploadNode = try await usecase.loadCameraUploadNode()
            } catch {}
            
            shouldLoad = false
        }
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
}
