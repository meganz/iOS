import Combine

protocol PhotoLibraryUseCaseProtocol {
    /// Load CameraUpload and MediaUpload node
    /// - Returns: PhotoLibraryContainerEntity, which contains CameraUpload and MediaUpload node itself
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity
    
    /// Load Camera/Media Upload photos and videos
    /// - Returns: Sorted nodes by modification time
    func cameraUploadPhotos() async throws -> [MEGANode]
    
    /// Load Cloud Drive photos and Camera/Media Upload videos
    /// - Returns: Sorted nodes by modification time
    func allPhotos() async throws -> [MEGANode]
}

struct PhotoLibraryUseCase<T: PhotoLibraryRepositoryProtocol, U: FilesSearchRepositoryProtocol>: PhotoLibraryUseCaseProtocol {
    private let photosRepository: T
    private let searchRepository: U
    
    enum ContainerType {
        case camera(MEGANode?)
        case media(MEGANode?)
    }
    
    init(photosRepository: T, searchRepository: U) {
        self.photosRepository = photosRepository
        self.searchRepository = searchRepository
    }
    
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        async let cameraUploadNode = try? await photosRepository.node(in: .camera)
        async let mediaUploadNode = try? await photosRepository.node(in: .media)
        
        return await PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode,
            mediaUploadNode: mediaUploadNode
        )
    }
    
    func cameraUploadPhotos() async throws -> [MEGANode] {
        let container = await photoLibraryContainer()
        let nodesCameraUpload = photosRepository.nodes(inParent: container.cameraUploadNode)
        let nodesMediaUpload = photosRepository.nodes(inParent: container.mediaUploadNode)
        var nodes = nodesCameraUpload + nodesMediaUpload
        
        sort(nodes: &nodes)
        
        return nodes
    }
    
    func allPhotos() async throws -> [MEGANode] {
        async let container = await photoLibraryContainer()
        async let photosFromCloudDrive = try await searchRepository.search(string: "", inNode: nil, sortOrderType: .defaultDesc, formatType: .photo)
        
        let videosCameraUpload = await photosRepository.videoNodes(inParent: container.cameraUploadNode)
        let videosMediaUpload = await photosRepository.videoNodes(inParent: container.mediaUploadNode)
        var nodes = videosCameraUpload + videosMediaUpload
        
        if let photos = try? await photosFromCloudDrive {
            nodes += photos
        }
        
        sort(nodes: &nodes)
        
        return nodes
    }
    
    // MARK: - Private
    
    private func sort(nodes: inout [MEGANode]) {
        nodes.sort { node1, node2 in
            if let modiTime1 = node1.modificationTime,
               let modiTime2 = node2.modificationTime {
                return modiTime1 > modiTime2
            }
            else {
                return node1.name ?? "" < node2.name ?? ""
            }
        }
    }
}
