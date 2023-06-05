import Foundation
import MEGADomain

protocol NodeDetailUseCaseProtocol {

    func ownerFolder(of node: HandleEntity) -> NodeEntity?

    func loadThumbnail(
        of node: HandleEntity,
        completion: @escaping (UIImage?) -> Void
    )
}

final class NodeDetailUseCase: NodeDetailUseCaseProtocol {

    private var sdkNodeClient: SDKNodeClient

    private var nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol

    init(
        sdkNodeClient: SDKNodeClient,
        nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol
    ) {
        self.sdkNodeClient = sdkNodeClient
        self.nodeThumbnailHomeUseCase = nodeThumbnailHomeUseCase
    }

    func ownerFolder(of node: HandleEntity) -> NodeEntity? {
        sdkNodeClient.findOwnerNode(node)?.toNodeEntity()
    }

    func loadThumbnail(
        of node: HandleEntity,
        completion: @escaping (UIImage?) -> Void
    ) {
        return nodeThumbnailHomeUseCase.loadThumbnail(of: node, completion: completion)
    }
}
