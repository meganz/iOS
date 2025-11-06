import UIKit

struct PhotosBrowserToolbarItem {
    let image: UIImage
    let action: UIAction
    
    init(image: UIImage, action: UIAction) {
        self.image = image
        self.action = action
    }
}
