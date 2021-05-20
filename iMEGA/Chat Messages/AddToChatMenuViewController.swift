
import UIKit

protocol AddToChatMenuViewControllerDelegate: AnyObject {
    func didTap(menu: AddToChatMenu)
    func shouldDisable(menu: AddToChatMenu) -> Bool
}

class AddToChatMenuViewController: UIViewController {
    
    lazy var menuView: AddToChatMenuItemsView = {
        let menuView = AddToChatMenuItemsView.instanceFromNib
        menuView.delegate = self
        return menuView
    }()
    
    weak var delegate: AddToChatMenuViewControllerDelegate?
    
    var menus: [AddToChatMenu]? {
        didSet {
            menuView.menus = menus
        }
    }
    
    var rowSpacing: CGFloat {
        return menuView.rowSpacing
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(menuView)
        menuView.autoPinEdgesToSuperviewEdges()
    }
    
    func updateMenus() {
        menuView.updateMenus()
    }
}

extension AddToChatMenuViewController: AddToChatMenuItemsViewDelegate {
    func didTap(menu: AddToChatMenu) {
        delegate?.didTap(menu: menu)
    }
    
    func shouldDisable(menu: AddToChatMenu) -> Bool {
        return delegate?.shouldDisable(menu: menu) ?? false
    }
}
