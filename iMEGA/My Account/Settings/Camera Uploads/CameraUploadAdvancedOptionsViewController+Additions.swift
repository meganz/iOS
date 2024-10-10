import MEGADesignToken

extension CameraUploadAdvancedOptionsViewController {
    @objc func configSwitchTintColors() {
        uploadAllBurstPhotosSwitch?.onTintColor = TokenColors.Support.success
        uploadVideosForlivePhotosSwitch?.onTintColor = TokenColors.Support.success
        uploadHiddenAlbumSwitch?.onTintColor = TokenColors.Support.success
        uploadSharedAlbumsSwitch?.onTintColor = TokenColors.Support.success
    }
}
