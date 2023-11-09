import UIKit

protocol AddToChatMenuViewControllerDelegate: AnyObject {
    func didTap(menu: AddToChatMenu)
}

class AddToChatMenuViewController: UIViewController {
    
    lazy var menuView: AddToChatMenuItemsView = {
        let menuView = AddToChatMenuItemsView.instanceFromNib
        menuView.delegate = self
        return menuView
    }()
    
    weak var delegate: (any AddToChatMenuViewControllerDelegate)?
    
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

        view.wrap(menuView)
    }
}

extension AddToChatMenuViewController: AddToChatMenuItemsViewDelegate {
    func didTap(menu: AddToChatMenu) {
        delegate?.didTap(menu: menu)
    }
}
