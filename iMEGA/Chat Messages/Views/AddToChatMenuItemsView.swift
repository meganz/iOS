
import UIKit

class AddToChatMenuItemsView: UIView {
    
    @IBOutlet var menuViews: [AddToChatMenuView]!
    
    var menus: [AddToChatMenu]? {
        didSet {
            guard let menus = menus,
                menuViews != nil,
                menus.count <= 8 else {
                return
            }
            
            menuViews.enumerated().forEach { (index, menuView) in
                if menus.count > index {
                    menuView.menu = menus[index]
                } else {
                    menuView.menu = nil
                }
            }
        }
    }
}
