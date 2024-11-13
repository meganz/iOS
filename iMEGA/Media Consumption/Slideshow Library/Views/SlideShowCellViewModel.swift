import Foundation
import MEGADomain

@MainActor
final class SlideShowCellViewModel: ObservableObject {
    
    typealias ImageSource = (image: UIImage, fileUrl: URL?)
    @Published private(set) var imageSource: ImageSource?
    
    private let node: NodeEntity
    private let loader: MediaEntityLoader
    private var loadThumbnailTask: Task<Void, Never>?
        
    deinit {
        loadThumbnailTask?.cancel()
    }
    
    init(node: NodeEntity,
         loader: MediaEntityLoader) {
        
        self.node = node
        self.loader = loader
        
        loadThumbnailTask = Task {
            imageSource = await loader.loadMediaEntity(forNode: node)
        }
    }
}
