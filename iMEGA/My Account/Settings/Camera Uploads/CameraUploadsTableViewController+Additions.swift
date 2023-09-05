import MEGAL10n

extension CameraUploadsTableViewController {
    @objc func showAccountExpiredAlert() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.presentAccountExpiredAlertIfNeeded()
    }
    @objc
    func configureNavigationBar() {
        let title = Strings.Localizable.cameraUploadsLabel
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
}
