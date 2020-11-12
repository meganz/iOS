
import UIKit

protocol AddToChatMenuItemsViewDelegate: class {
    func didTap(menu: AddToChatMenu)
    func shouldDisable(menu: AddToChatMenu) -> Bool
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
                    let menu = menus[index]
                    menuView.menu = menu
                    update(menuView: menuView)
                } else {
                    menuView.menu = nil
                }
            }
        }
    }
    
    func updateMenus() {
        menuViews.forEach { menuView in
            update(menuView: menuView)
        }
    }
    
    private func update(menuView: AddToChatMenuView) {
        guard let delegate = delegate  else {
            return
        }
        
        if let menu = menuView.menu,
            menu.dynamicKey == true {
            menuView.disable(delegate.shouldDisable(menu: menu))
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
