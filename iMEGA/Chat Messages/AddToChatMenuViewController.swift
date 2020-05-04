
import UIKit

protocol AddToChatMenuViewControllerDelegate: class {
    func didTap(menu: AddToChatMenu)
}

class AddToChatMenuViewController: UIViewController {
    
    lazy var menuView = AddToChatMenuItemsView.instanceFromNib
    weak var delegate: AddToChatMenuViewControllerDelegate?
    
    var menus: [AddToChatMenu]? {
        didSet {
            menuView.menus = menus
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        menuView.delegate = self
        view.addSubview(menuView)
        menuView.autoPinEdgesToSuperviewEdges()
    }
}

extension AddToChatMenuViewController: AddToChatMenuItemsViewDelegate {
    func didTap(menu: AddToChatMenu) {
        delegate?.didTap(menu: menu)
    }
}
