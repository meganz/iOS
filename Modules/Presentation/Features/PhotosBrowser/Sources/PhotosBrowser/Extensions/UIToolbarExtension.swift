import UIKit

extension UIToolbar {
    func configure(with toolbarItems: [PhotosBrowserToolbarItem]) {
        var barButtonItems: [UIBarButtonItem] = []
        
        for (index, item) in toolbarItems.enumerated() {
            let button = UIBarButtonItem(image: item.image, primaryAction: item.action)
            
            barButtonItems.append(button)
            if index < toolbarItems.count - 1 {
                barButtonItems.append(UIBarButtonItem.flexibleSpace())
            }
        }
        
        self.items = barButtonItems
    }
}
