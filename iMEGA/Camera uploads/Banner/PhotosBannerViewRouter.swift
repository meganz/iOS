protocol PhotosBannerViewRouting {
    func goToSettings()
}

struct PhotosBannerViewRouter: PhotosBannerViewRouting {
    
    func goToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}
