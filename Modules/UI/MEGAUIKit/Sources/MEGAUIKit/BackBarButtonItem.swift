import UIKit

// this is used to implement back buttons on the nav bar while keeping
// the custom titles of screens or empty titles on the back buttons
// It works with conjunction with MEGANavigationController which inspects
// navigationItem.backBarButtonItem to check if it's BackBarButtonItem and
// then grabs menuTitle to construct menu items to pop to each view controller in the hierarchy
public final class BackBarButtonItem: UIBarButtonItem {
    public private(set) var menuTitle: String?

    public convenience init(title: String?, menuTitle: String) {
        let _title = title ?? ""
        self.init(title: _title, style: .plain, target: nil, action: nil)
        self.menuTitle = menuTitle
    }
    
    public convenience init(menuTitle: String) {
        self.init(title: nil, menuTitle: menuTitle)
    }
    
    public override var menu: UIMenu? {
        get {
            return super.menu
        }
        set {
            if let newValue {
                if newValue.children.allSatisfy({ element in !(element is UIDeferredMenuElement) }) {
                    super.menu = newValue
                }
            }
        }
    }
}
