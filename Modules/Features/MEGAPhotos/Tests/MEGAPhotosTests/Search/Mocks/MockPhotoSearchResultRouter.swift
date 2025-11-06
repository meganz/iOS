import MEGADomain
@testable import MEGAPhotos
import UIKit

class MockPhotoSearchResultRouter: PhotoSearchResultRouterProtocol {
    struct SelectedPhoto {
        let photo: NodeEntity
        let otherPhotos: [NodeEntity]
    }
    private(set) var moreActionOnNodeHandle: HandleEntity?
    @Published private(set) var selectedAlbum: AlbumEntity?
    @Published private(set) var selectedPhoto: SelectedPhoto?
    
    func didTapMoreAction(on node: HandleEntity, button: UIButton) {
        moreActionOnNodeHandle = node
    }
    
    func didSelectAlbum(_ album: AlbumEntity) {
        selectedAlbum = album
    }
    
    func didSelectPhoto(_ photo: NodeEntity, otherPhotos: [NodeEntity]) {
        selectedPhoto = .init(photo: photo, otherPhotos: otherPhotos)
    }
}
