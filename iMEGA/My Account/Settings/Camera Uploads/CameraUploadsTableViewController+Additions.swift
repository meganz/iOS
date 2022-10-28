
extension CameraUploadsTableViewController {
    @objc func showAccountExpiredAlert() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.presentAccountExpiredAlertIfNeeded()
    }
}
