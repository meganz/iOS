import Foundation

extension MyAccountHallViewController {
    
    @objc func showSettings() {
        let settingRouter = SettingViewRouter(presenter: navigationController)
        settingRouter.start()
    }
}
