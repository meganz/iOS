import MEGADomain
@testable import MEGAPhotos
import UIKit

class MockPhotoSearchResultRouter: PhotoSearchResultRouterProtocol {
    private(set) var moreActionOnNodeHandle: HandleEntity?
    
    func didTapMoreAction(on node: HandleEntity, button: UIButton) {
        moreActionOnNodeHandle = node
    }
}
