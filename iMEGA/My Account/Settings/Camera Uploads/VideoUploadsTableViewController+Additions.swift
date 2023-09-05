import MEGAL10n

extension VideoUploadsTableViewController {
    @objc func updateNavigationTitle() {
        let title = Strings.Localizable.CameraUploads.VideoUploads.title
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
}
