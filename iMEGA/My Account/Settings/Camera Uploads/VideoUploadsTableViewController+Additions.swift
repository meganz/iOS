import MEGAL10n

extension VideoUploadsTableViewController {
    @objc func updateNavigationTitle() {
        let title = Strings.Localizable.CameraUploads.VideoUploads.title
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
    
    @objc func configLabelsTextColor() {
        uploadVideosLabel?.textColor = UIColor.primaryTextColor()
        hevcLabel?.textColor = UIColor.primaryTextColor()
        videoQualityLabel?.textColor = UIColor.primaryTextColor()
        h264Label?.textColor = UIColor.primaryTextColor()
    }
}
