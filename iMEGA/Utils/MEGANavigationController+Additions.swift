import MEGAUIKit

extension MEGANavigationController {
    
    @objc
    func updateBackButtonMenu() {
        guard let topItem = navigationBar.topItem else {
            MEGALogWarning("[Navigation] no top item")
            return
        }
        guard let backBarButtonItem = topItem.backBarButtonItem else {
            MEGALogWarning("[Navigation] no back button to set menu")
            return
        }
        backBarButtonItem.menu = UIMenu(items: currentBackButtonMenuItems())
    }
    
    @objc
    func currentBackButtonMenuItems() -> [UIMenuElement] {
        var menuItems = [UIMenuElement]()
        for navigationItem in navigationBar.items ?? [] {
            if navigationItem.backBarButtonItem == nil {
                MEGALogWarning("[Navigation] no back button item ")
                continue
            }
            guard
                let backButton = navigationItem.backBarButtonItem as? BackBarButtonItem
            else {
                MEGALogError("[Navigation] we should only use BackBarButtonItem")
                continue
            }
            guard let menuTitle = backButton.menuTitle else {
                MEGALogError("[Navigation] we should have a title always")
                continue
            }
            
            let action = UIAction(title: menuTitle) { [weak self, weak navigationItem] _ in
                guard let self, let navigationItem else { return }
                if let viewController = self.viewControllers.first(where: { $0.navigationItem == navigationItem }) {
                    self.popToViewController(viewController, animated: true)
                }
            }
            menuItems.append(action)
        }
        menuItems.reverse()
        return menuItems
    }
}

extension UIMenu {
    convenience init(items: [UIMenuElement]) {
        self.init(title: "", image: nil, identifier: nil, options: [], children: items)
    }
}
