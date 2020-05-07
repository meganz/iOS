
import UIKit

protocol AddToChatMenuItemsViewDelegate: class {
    func didTap(menu: AddToChatMenu)
}

class AddToChatMenuItemsView: UIView {
    
    @IBOutlet var menuViews: [AddToChatMenuView]!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet var menuHolderStackView: UIStackView!

    weak var delegate: AddToChatMenuItemsViewDelegate?
    
    var rowSpacing: CGFloat {
        return menuHolderStackView.spacing
    }

    var menus: [AddToChatMenu]? {
        didSet {
            guard let menus = menus,
                menuViews != nil,
                menus.count <= menuViews.count else {
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
    
    @IBAction func buttonTapped(_ button: UIButton) {
        guard let tappedIndex = buttons.firstIndex(of: button),
            let menus = menus,
            let delegate = delegate else {
                return
        }
        
        delegate.didTap(menu: menus[tappedIndex])
    }
}
