import Foundation

protocol NodeDetailUseCaseProtocol {

    func ownerFolder(of node: MEGAHandle) -> SDKNode?

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

    func ownerFolder(of node: MEGAHandle) -> SDKNode? {
        return sdkNodeClient.findOwnerNode(node).map(SDKNode.init(with:))
    }

    func loadThumbnail(
        of node: MEGAHandle,
        completion: @escaping (UIImage?) -> Void
    ) {
        return nodeThumbnailUseCase.loadThumbnail(of: node, completion: completion)
    }
}
