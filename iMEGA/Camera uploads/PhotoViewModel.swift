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
    
    init(
        photoUpdatePublisher: PhotoUpdatePublisher,
        photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    ) {
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        super.init()
        loadSortOrderType()
    }
    
    @objc func onCameraAndMediaNodesUpdate(nodeList: MEGANodeList) {
        Task {
            do {
                let container = await photoLibraryUseCase.photoLibraryContainer()
                
                guard FeatureFlag.shouldRemoveHomeImage || shouldProcessOnNodesUpdate(nodeList: nodeList, container: container) else { return }
                
                let photos = try await FeatureFlag.shouldRemoveHomeImage ? photoLibraryUseCase.allPhotos() : photoLibraryUseCase.cameraUploadPhotos()
                
                updateMediaNodesArray(photos)
            }
            catch {}
        }
    }
    
    @objc func loadAllPhotos() {
        Task {
            do {
                let photos = try await FeatureFlag.shouldRemoveHomeImage ? photoLibraryUseCase.allPhotos() : photoLibraryUseCase.cameraUploadPhotos()
                updateMediaNodesArray(photos)
            }
            catch {}
        }
    }
    
    func sortOrderType(forKey key: SortingKeys) -> SortOrderType {
        let sortType = SortOrderType(megaSortOrderType: Helper.sortType(for: key.rawValue))
        return sortType != .newest && sortType != .oldest ? .newest : sortType
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
    
    private func reorderPhotos(_ sortType: SortOrderType?, mediaNodes: [MEGANode]) -> [MEGANode] {
        guard let sortType = sortType,
              sortType == .newest || sortType == .oldest else { return mediaNodes }
    
        return mediaNodes.sorted { node1, node2 in
            guard let date1 = node1.modificationTime,
                  let date2 = node2.modificationTime else { return node1.name ?? "" < node2.name ?? "" }

            return sortType == .newest ? date1 > date2 : date1 < date2
        }
    }
    
    private func updateMediaNodesArray(_ photos: [MEGANode]){
        mediaNodesArray = reorderPhotos(cameraUploadExplorerSortOrderType, mediaNodes: photos)
    }
}
