protocol WarningViewRouting {
    func goToSettings()
}

struct WarningViewRouter: WarningViewRouting {
    func goToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}
