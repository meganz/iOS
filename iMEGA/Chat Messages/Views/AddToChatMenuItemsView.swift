import UIKit

protocol AddToChatMenuItemsViewDelegate: AnyObject {
    func didTap(menu: AddToChatMenu)
}

class AddToChatMenuItemsView: UIView {
    
    @IBOutlet var menuViews: [AddToChatMenuView]!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet var menuHolderStackView: UIStackView!

    weak var delegate: (any AddToChatMenuItemsViewDelegate)?
    
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
                    let menu = menus[index]
                    menuView.menu = menu
                } else {
                    menuView.menu = nil
                }
            }
        }
    }
    
    @IBAction func buttonTapped(_ button: UIButton) {
        guard let tappedIndex = buttons.firstIndex(of: button),
            let menus = menus,
            tappedIndex < menus.count,
            let delegate = delegate else {
                return
        }
        
        let menuView = menuViews[tappedIndex]
        if !menuView.disabled {
            delegate.didTap(menu: menus[tappedIndex])
        }
    }
}
