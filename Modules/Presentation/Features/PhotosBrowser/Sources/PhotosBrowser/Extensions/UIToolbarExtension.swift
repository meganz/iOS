import UIKit

extension UIToolbar {
    func configure(with images: [UIImage], actions: [UIAction], target: PhotosBrowserViewController) {
        var barButtonItems: [UIBarButtonItem] = []
        
        for (index, image) in images.enumerated() {
            let button = UIBarButtonItem(image: image, primaryAction: actions[index])
            
            barButtonItems.append(button)
            if index < images.count - 1 {
                barButtonItems.append(UIBarButtonItem.flexibleSpace())
            }
        }
        
        self.items = barButtonItems
    }
}
