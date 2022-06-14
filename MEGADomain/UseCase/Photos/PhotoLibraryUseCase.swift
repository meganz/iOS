import Combine

protocol PhotoLibraryUseCaseProtocol {
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity
    func allPhotos() async throws -> [MEGANode]
}

struct PhotoLibraryUseCase<T: PhotoLibraryRepositoryProtocol>: PhotoLibraryUseCaseProtocol {
    private let photosRepository: T
    
    enum ContainerType {
        case camera(MEGANode?)
        case media(MEGANode?)
    }
    
    init(repository: T) {
        photosRepository = repository
    }
    
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        async let cameraUploadNode = try? await photosRepository.node(in: .camera)
        async let mediaUploadNode = try? await photosRepository.node(in: .media)
        
        return await PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode,
            mediaUploadNode: mediaUploadNode
        )
    }
    
    func allPhotos() async throws -> [MEGANode] {
        let container = await photoLibraryContainer()
        
        let nodesFromCameraUpload = photosRepository.nodes(inParent: container.cameraUploadNode)
        let nodesFromMediaUpload = photosRepository.nodes(inParent: container.mediaUploadNode)
        var nodes = nodesFromCameraUpload + nodesFromMediaUpload
        
        nodes.sort { node1, node2 in
            if let modiTime1 = node1.modificationTime,
               let modiTime2 = node2.modificationTime {
                return modiTime1 > modiTime2
            }
            else {
                return node1.name ?? "" < node2.name ?? ""
            }
        }
        
        if nodes.count > 0 {
            return nodes
        }
        else {
            throw PhotoLibraryErrorEntity.nodeDoesNotExist
        }
    }
}
