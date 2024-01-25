extension CameraUploadAdvancedOptionsViewController {
    @objc func configSwitchTintColors() {
        uploadAllBurstPhotosSwitch?.onTintColor = UIColor.switchOnTintColor()
        uploadVideosForlivePhotosSwitch?.onTintColor = UIColor.switchOnTintColor()
        uploadHiddenAlbumSwitch?.onTintColor = UIColor.switchOnTintColor()
        uploadSharedAlbumsSwitch?.onTintColor = UIColor.switchOnTintColor()
    }
}
