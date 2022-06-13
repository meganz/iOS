import Combine

protocol PhotoLibraryUseCaseProtocol {
    func retrieveCameraAndMediaContents() async throws -> PhotoLibraryResultEntity
}

struct PhotoLibraryUseCase<T: PhotoLibraryRepositoryProtocol>: PhotoLibraryUseCaseProtocol {
    private let photosRepository: T
    
    init(repository: T) {
        photosRepository = repository
    }
    
    func retrieveCameraAndMediaContents() async throws -> PhotoLibraryResultEntity {
        let photoLibraryTask = Task { () -> PhotoLibraryResultEntity in
            async let cameraUploadNode = try? await photosRepository.node(in: .camera)
            async let mediaUploadNode = try? await photosRepository.node(in: .media)
            
            var nodes = await [
                photosRepository.nodes(inParent: cameraUploadNode),
                photosRepository.nodes(inParent: mediaUploadNode)
            ].flatMap { $0 }
            
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
                return await PhotoLibraryResultEntity(
                    cameraUploadNode: cameraUploadNode,
                    mediaUploadNode: mediaUploadNode,
                    photos: nodes
                )
            }
            else {
                throw PhotoLibraryErrorEntity.nodeDoesNotExist
            }
        }
        
        let result = await photoLibraryTask.result
        let photoLibraryResultEntity = try result.get()
        return photoLibraryResultEntity
    }
}
