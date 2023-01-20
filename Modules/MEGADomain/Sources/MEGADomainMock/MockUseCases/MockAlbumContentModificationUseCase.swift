import Foundation
import MEGADomain

public struct MockAlbumContentModificationUseCase: AlbumContentModificationUseCaseProtocol {
    private var resultEntity = AlbumElementsResultEntity(success: 0, failure: 0)
    
    public init(resultEntity: AlbumElementsResultEntity? = nil) {
        if let resultEntity = resultEntity {
            self.resultEntity = resultEntity
        }
    }

    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        return resultEntity
    }
}
