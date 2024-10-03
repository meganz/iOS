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
        enableCameraUploadsLabel.textColor = UIColor.primaryTextColor()
        uploadVideosInfoLabel.textColor = UIColor.primaryTextColor()
        uploadVideosLabel.textColor = UIColor.primaryTextColor()
        targetFolderLabel.textColor = UIColor.primaryTextColor()
        heicLabel.textColor = UIColor.primaryTextColor()
        jpgLabel.textColor = UIColor.primaryTextColor()
        includeGPSTagsLabel.textColor = UIColor.primaryTextColor()
        useCellularConnectionLabel.textColor = UIColor.primaryTextColor()
        advancedLabel.textColor = UIColor.primaryTextColor()
        useCellularConnectionForVideosLabel.textColor = UIColor.primaryTextColor()
    }
}
