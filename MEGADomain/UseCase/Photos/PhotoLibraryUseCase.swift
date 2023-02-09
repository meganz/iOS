import Combine
import MEGADomain

protocol PhotoLibraryUseCaseProtocol: Sendable {
    /// Load CameraUpload and MediaUpload node
    /// - Returns: PhotoLibraryContainerEntity, which contains CameraUpload and MediaUpload node itself
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity
    
    /// Load Camera/Media Upload photos and videos
    /// - Returns: Sorted nodes by modification time
    func cameraUploadPhotos() async throws -> [NodeEntity]
    
    /// Load Cloud Drive(include camera upload and media upload) photos and videos
    /// - Returns: All images and videos nodes from cloud drive
    func allPhotos() async throws -> [NodeEntity]
    
    /// Load Cloud Drive(except camera upload and media upload) images and videos
    /// - Returns: All images and videos nodes
    func allPhotosFromCloudDriveOnly() async throws -> [NodeEntity]
    
    /// Load camera upload and media upload images and videos
    /// - Returns: All images and videos nodes
    func allPhotosFromCameraUpload() async throws -> [NodeEntity]
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
        async let cameraUploadNode = try? await photosRepository.photoSourceNode(for: .camera)
        async let mediaUploadNode = try? await photosRepository.photoSourceNode(for: .media)
        
        return await PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode,
            mediaUploadNode: mediaUploadNode
        )
    }
    
    func cameraUploadPhotos() async throws -> [NodeEntity] {
        let container = await photoLibraryContainer()
        let nodesCameraUpload = photosRepository.visualMediaNodes(inParent: container.cameraUploadNode)
        let nodesMediaUpload = photosRepository.visualMediaNodes(inParent: container.mediaUploadNode)
        let nodes = nodesCameraUpload + nodesMediaUpload

        return nodes
    }
    
    func allPhotos() async throws -> [NodeEntity] {
        try await loadAllPhotos()
    }
    
    func allPhotosFromCloudDriveOnly() async throws -> [NodeEntity] {
        let container = await photoLibraryContainer()
        let nodes: [NodeEntity] = try await loadAllPhotos()
        
        return nodes.filter({$0.parentHandle != container.cameraUploadNode?.handle && $0.parentHandle != container.mediaUploadNode?.handle})
    }
    
    func allPhotosFromCameraUpload() async throws -> [NodeEntity] {
        let container = await photoLibraryContainer()
        
        async let photosCameraUpload = photosRepository.visualMediaNodes(inParent: container.cameraUploadNode)
        async let photosMediaUpload = photosRepository.visualMediaNodes(inParent: container.mediaUploadNode)
        
        var nodes: [NodeEntity] = []
        nodes.append(contentsOf: await photosCameraUpload)
        nodes.append(contentsOf: await photosMediaUpload)
        return nodes
    }
    
    // MARK: - Private
    private func loadAllPhotos() async throws -> [NodeEntity] {
        let photosFromCloudDrive = try? await searchRepository.search(string: "", parent: nil, sortOrderType: .defaultDesc, formatType: .photo)
        let videosFromCloudDrive = try? await searchRepository.search(string: "", parent: nil, sortOrderType: .defaultDesc, formatType: .video)
        
        var nodes: [NodeEntity] = []
        
        if let photos = photosFromCloudDrive {
            nodes.append(contentsOf: photos)
        }

        if let videos = videosFromCloudDrive {
            nodes.append(contentsOf: videos)
        }
        
        return nodes
    }
}
