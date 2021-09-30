import Foundation

protocol NodeDetailUseCaseProtocol {

    func ownerFolder(of node: MEGAHandle) -> NodeEntity?

    func loadThumbnail(
        of node: MEGAHandle,
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

    func ownerFolder(of node: MEGAHandle) -> NodeEntity? {
        return sdkNodeClient.findOwnerNode(node).map(NodeEntity.init(node: ))
    }

    
    func loadThumbnail(
        of node: MEGAHandle,
        completion: @escaping (UIImage?) -> Void
    ) {
        return nodeThumbnailHomeUseCase.loadThumbnail(of: node, completion: completion)
    }
}
