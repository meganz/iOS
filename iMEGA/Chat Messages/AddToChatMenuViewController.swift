
import UIKit

class AddToChatMenuViewController: UIViewController {
    
    lazy var menuView = AddToChatMenuItemsView.instanceFromNib
    
    var menus: [AddToChatMenu]? {
        didSet {
            menuView.menus = menus
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(menuView)
        menuView.autoPinEdgesToSuperviewEdges()
    }


}
