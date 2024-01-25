import MEGAL10n

extension VideoUploadsTableViewController {
    @objc func updateNavigationTitle() {
        let title = Strings.Localizable.CameraUploads.VideoUploads.title
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
    
    @objc func configLabelsTextColor() {
        uploadVideosLabel?.textColor = UIColor.cellTitleColor(for: traitCollection)
        hevcLabel?.textColor = UIColor.cellTitleColor(for: traitCollection)
        videoQualityLabel?.textColor = UIColor.cellTitleColor(for: traitCollection)
        h264Label?.textColor = UIColor.cellTitleColor(for: traitCollection)
    }
}
