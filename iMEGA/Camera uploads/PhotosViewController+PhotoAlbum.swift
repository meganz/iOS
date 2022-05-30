import Foundation
import UIKit

extension PhotosViewController {
    @objc var objcWrapper_parent: UIViewController {
        if let parent = parentPhotoAlbumsController {
            return parent
        } else {
            return self
        }
    }
}
