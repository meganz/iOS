
extension SettingsTableViewController {
    @objc func presentCallsSettings() {
        guard let navigationController = navigationController else { return }
        CallsSettingsViewRouter(presenter: navigationController).start()
    }
}
