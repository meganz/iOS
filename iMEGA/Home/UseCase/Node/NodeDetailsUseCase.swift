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

    private var nodeThumbnailUseCase: NodeThumbnailUseCaseProtocol

    init(
        sdkNodeClient: SDKNodeClient,
        nodeThumbnailUseCase: NodeThumbnailUseCaseProtocol
    ) {
        self.sdkNodeClient = sdkNodeClient
        self.nodeThumbnailUseCase = nodeThumbnailUseCase
    }

    func ownerFolder(of node: MEGAHandle) -> NodeEntity? {
        return sdkNodeClient.findOwnerNode(node).map(NodeEntity.init(with:))
    }

    func loadThumbnail(
        of node: MEGAHandle,
        completion: @escaping (UIImage?) -> Void
    ) {
        return nodeThumbnailUseCase.loadThumbnail(of: node, completion: completion)
    }
}
