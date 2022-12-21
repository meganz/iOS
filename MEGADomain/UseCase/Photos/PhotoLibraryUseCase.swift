import Combine

protocol PhotoLibraryUseCaseProtocol {
    /// Load CameraUpload and MediaUpload node
    /// - Returns: PhotoLibraryContainerEntity, which contains CameraUpload and MediaUpload node itself
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity
    
    /// Load Camera/Media Upload photos and videos
    /// - Returns: Sorted nodes by modification time
    func cameraUploadPhotos() async throws -> [MEGANode]
    
    /// Load Cloud Drive(include camera upload and media upload) photos and videos
    /// - Returns: All images and videos nodes from cloud drive
    func allPhotos() async throws -> [MEGANode]
    
    /// Load Cloud Drive(except camera upload and media upload) images and videos
    /// - Returns: All images and videos nodes
    func allPhotosFromCloudDriveOnly() async throws -> [MEGANode]
    
    /// Load camera upload and media upload images and videos
    /// - Returns: All images and videos nodes
    func allPhotosFromCameraUpload() async throws -> [MEGANode]
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
        let nodes = nodesCameraUpload + nodesMediaUpload

        return nodes
    }
    
    func allPhotos() async throws -> [MEGANode] {
        try await loadAllPhotos()
    }
    
    func allPhotosFromCloudDriveOnly() async throws -> [MEGANode] {
        let container = await photoLibraryContainer()
        let nodes: [MEGANode] = try await loadAllPhotos()
        
        return nodes.filter({$0.parentHandle != container.cameraUploadNode?.handle && $0.parentHandle != container.mediaUploadNode?.handle})
    }
    
    func allPhotosFromCameraUpload() async throws -> [MEGANode] {
        let container = await photoLibraryContainer()
        
        async let photosCameraUpload = photosRepository.nodes(inParent: container.cameraUploadNode)
        async let photosMediaUpload = photosRepository.nodes(inParent: container.mediaUploadNode)
        
        var nodes: [MEGANode] = []
        nodes.append(contentsOf: await photosCameraUpload)
        nodes.append(contentsOf: await photosMediaUpload)
        return nodes
    }
    
    // MARK: - Private
    private func loadAllPhotos() async throws -> [MEGANode] {
        let photosFromCloudDrive = try? await searchRepository.search(string: "", inNode: nil, sortOrderType: .defaultDesc, formatType: .photo)
        let videosFromCloudDrive = try? await searchRepository.search(string: "", inNode: nil, sortOrderType: .defaultDesc, formatType: .video)
        
        var nodes: [MEGANode] = []
        
        if let photos = photosFromCloudDrive {
            nodes.append(contentsOf: photos)
        }
        
        if let videos = videosFromCloudDrive {
            nodes.append(contentsOf: videos)
        }
        
        return nodes
    }
}
