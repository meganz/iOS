import Combine

final class PhotoViewModel: NSObject {
    @objc var mediaNodesArray: [MEGANode] = [MEGANode]() {
        didSet {
            guard cameraUploadExplorerSortOrderType != nil else { return }
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    var cameraUploadExplorerSortOrderType: SortOrderType? {
        didSet {
            if let orderType = cameraUploadExplorerSortOrderType {
                mediaNodesArray = reorderPhotos(orderType, mediaNodes: mediaNodesArray)
            }
        }
    }
    
    enum SortingKeys: String {
        case cameraUploadExplorerFeed
    }
    private var filterOptions: PhotosFilterOptions = [.allMedia, .allLocations]
    
    var filterType: PhotosFilterOptions = .allMedia
    var filterLocation: PhotosFilterOptions = .allLocations
    
    init(
        photoUpdatePublisher: PhotoUpdatePublisher,
        photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    ) {
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        super.init()
        loadSortOrderType()
    }
    
    @objc func onCameraAndMediaNodesUpdate(nodeList: MEGANodeList, with featureFlag: Bool) {
        Task {
            do {
                let container = await photoLibraryUseCase.photoLibraryContainer()
                
                guard featureFlag || shouldProcessOnNodesUpdate(nodeList: nodeList, container: container) else { return }
                
                let photos = try await featureFlag ? loadFilteredPhotos() : photoLibraryUseCase.cameraUploadPhotos()
                self.mediaNodesArray = photos
            }
            catch {}
        }
    }
    
    @objc func loadAllPhotos(with featureFlag: Bool) {
        Task {
            do {
                let photos = try await featureFlag ? loadFilteredPhotos() : photoLibraryUseCase.cameraUploadPhotos()
                self.mediaNodesArray = photos
            }
            catch {}
        }
    }
    
    func loadFilteredPhotos() async throws -> [MEGANode] {
        let filterOptions: PhotosFilterOptions = [filterType, filterLocation]
        var nodes: [MEGANode]
        
        switch filterOptions {
        case .allVisualFiles, .allImages, .allVideos:
            nodes = try await photoLibraryUseCase.allPhotos()
        case .cloudDriveAll, .cloudDriveImages, .cloudDriveVideos:
            nodes = try await photoLibraryUseCase.allPhotosFromCloudDriveOnly()
        case .cameraUploadAll, .cameraUploadImages, .cameraUploadVideos:
            nodes = try await photoLibraryUseCase.allPhotosFromCameraUpload()
        default: nodes = []
        }
        
        filter(nodes: &nodes, with: filterType)
        
        return nodes
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
    
    private func loadSortOrderType() {
        let sortOrderType = sortOrderType(forKey: .cameraUploadExplorerFeed)
        cameraUploadExplorerSortOrderType = sortOrderType
    }
    
    private func updateMediaNodesArray(_ photos: [MEGANode]){
        mediaNodesArray = reorderPhotos(cameraUploadExplorerSortOrderType, mediaNodes: photos)
    }
}
