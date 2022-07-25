
extension SettingsTableViewController {
    @objc func presentCallsSettings() {
        guard let navigationController = navigationController else { return }
        CallsSettingsViewRouter(presenter: navigationController).start()
    }
    
    @objc func showQASettingsView() {
        guard let navigationController = navigationController else { return }
        QASettingsRouter(navigationController: navigationController).start()
    }
}
