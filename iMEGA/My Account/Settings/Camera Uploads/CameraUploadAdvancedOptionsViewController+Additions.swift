import MEGADesignToken

extension CameraUploadAdvancedOptionsViewController {
    @objc func configSwitchTintColors() {
        uploadAllBurstPhotosSwitch?.onTintColor = TokenColors.Support.success
        uploadVideosForlivePhotosSwitch?.onTintColor = TokenColors.Support.success
        uploadHiddenAlbumSwitch?.onTintColor = TokenColors.Support.success
        uploadSharedAlbumsSwitch?.onTintColor = TokenColors.Support.success
    }
    
    @objc func makeViewModel() -> CameraUploadsAdvancedOptionsViewModel {
        CameraUploadsAdvancedOptionsViewModel()
    }
    
    @objc func trackLivePhotoVideoUploadsEvent(_ enabled: Bool) {
        viewModel.trackEvent(.livePhotoVideoUploads(enabled))
    }
    
    @objc func trackBurstPhotosUploadEvent(_ enabled: Bool) {
        viewModel.trackEvent(.burstPhotosUpload(enabled))
    }
    
    @objc func trackHiddenAlbumUploadEvent(_ enabled: Bool) {
        viewModel.trackEvent(.hiddenAlbumUpload(enabled))
    }
    
    @objc func trackSharedAlbumsUploadEvent(_ enabled: Bool) {
        viewModel.trackEvent(.sharedAlbumsUpload(enabled))
    }
    
    @objc func trackITunesSyncedAlbumsUploadEvent(_ enabled: Bool) {
        viewModel.trackEvent(.iTunesSyncedAlbumsUpload(enabled))
    }
}
