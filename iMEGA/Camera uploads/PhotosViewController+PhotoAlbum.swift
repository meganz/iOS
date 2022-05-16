import Foundation
import UIKit

extension PhotosViewController {
    @objc var objcWrapper_parent: UIViewController {
        if FeatureFlag.isAlbumEnabled, let parent = parentPhotoAlbumsController {
            return parent
        } else {
            return self
        }
    }
}
