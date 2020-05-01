
import UIKit

protocol AddToChatMenuViewControllerDelegate: class {
    func didTap(itemAtIndex index: Int, viewController: AddToChatMenuViewController)
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
    func didTap(itemAtIndex index: Int) {
        delegate?.didTap(itemAtIndex: index, viewController: self)
    }
}
