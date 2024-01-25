import MEGAL10n

extension CameraUploadsTableViewController {
    @objc
    func showAccountExpiredAlert() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.presentAccountExpiredAlertIfNeeded()
    }
    
    @objc
    func configureNavigationBar() {
        let title = Strings.Localizable.cameraUploadsLabel
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
    
    @objc 
    func configLabelsTextColor() {
        enableCameraUploadsLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        uploadVideosInfoLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        uploadVideosLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        targetFolderLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        heicLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        jpgLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        includeGPSTagsLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        useCellularConnectionLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        advancedLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
        useCellularConnectionForVideosLabel.textColor = UIColor.cellTitleColor(for: traitCollection)
    }
}
