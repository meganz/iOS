import Combine

final class PhotoViewModel: NSObject {
    @objc var mediaNodesArray: [MEGANode] = [MEGANode]() {
        didSet {
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    
    init(
        photoUpdatePublisher: PhotoUpdatePublisher,
        photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    ) {
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        super.init()
    }
    
    @objc func onCameraAndMediaNodesUpdate(nodeList: MEGANodeList) {
        Task {
            do {
                let container = await photoLibraryUseCase.photoLibraryContainer()
                
                guard FeatureFlag.shouldRemoveHomeImage || shouldProcessOnNodesUpdate(nodeList: nodeList, container: container) else { return }
                
                let photos = try await FeatureFlag.shouldRemoveHomeImage ? photoLibraryUseCase.allPhotos() : photoLibraryUseCase.cameraUploadPhotos()
                self.mediaNodesArray = photos
            }
            catch {}
        }
    }
    
    @objc func loadAllPhotos() {
        Task {
            do {
                let photos = try await FeatureFlag.shouldRemoveHomeImage ? photoLibraryUseCase.allPhotos() : photoLibraryUseCase.cameraUploadPhotos()
                self.mediaNodesArray = photos
            }
            catch {}
        }
    }
    
    // MARK: - Private
    private func shouldProcessOnNodesUpdate(
        nodeList: MEGANodeList,
        container: PhotoLibraryContainerEntity
    ) -> Bool {
        let cameraUploadNodesModified = nodeList.mnz_shouldProcessOnNodesUpdate(
            forParentNode: container.cameraUploadNode,
            childNodesArray: mediaNodesArray
        )
        
        let mediaUploadNodesModified = nodeList.mnz_shouldProcessOnNodesUpdate(
            forParentNode: container.mediaUploadNode,
            childNodesArray: mediaNodesArray
        )
        
        return cameraUploadNodesModified || mediaUploadNodesModified
    }
}
