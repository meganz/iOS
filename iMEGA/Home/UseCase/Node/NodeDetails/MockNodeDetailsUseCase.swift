import Foundation
@testable import MEGA
import MEGADomain

final class MockNodeDetailUseCase: NodeDetailUseCaseProtocol {
    private let owner: NodeEntity?
    private let thumbnail: UIImage?

    init(
        owner: NodeEntity? = nil,
        thumbnail: UIImage? = nil
    ) {
        self.owner = owner
        self.thumbnail = thumbnail
    }
    func ownerFolder(of node: HandleEntity) -> NodeEntity? {
        owner
    }

    func loadThumbnail(of node: HandleEntity, completion: @escaping (UIImage?) -> Void) {
        completion(thumbnail)
    }
}
