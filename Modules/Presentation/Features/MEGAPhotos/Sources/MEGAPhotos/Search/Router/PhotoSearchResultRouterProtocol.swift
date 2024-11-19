import MEGADomain
import UIKit

@MainActor
public protocol PhotoSearchResultRouterProtocol: Sendable {
    func didTapMoreAction(on node: HandleEntity, button: UIButton)
    func didSelectAlbum(_ album: AlbumEntity)
    func didSelectPhoto(_ photo: NodeEntity, otherPhotos: [NodeEntity])
}
