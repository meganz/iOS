import Combine

final class PhotoViewModel: NSObject {
    @objc var cameraUploadParentNode: MEGANode?
    @objc var mediaUploadParentNode: MEGANode?
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
    
    @objc func retrieveCameraAndMediaContents() {
        Task {
            do {
                let photoLibraryResult = try await photoLibraryUseCase.retrieveCameraAndMediaContents()
                self.mediaNodesArray = photoLibraryResult.photos
                if let cuNode = photoLibraryResult.cameraUploadNode {
                    self.cameraUploadParentNode = cuNode
                }
                if let muNode = photoLibraryResult.mediaUploadNode {
                    self.mediaUploadParentNode = muNode
                }
                
            }
            catch {
                self.mediaNodesArray = []
            }
        }
    }
}
