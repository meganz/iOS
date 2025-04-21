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
    
    @objc func makeViewModel() -> VideoUploadsViewModel {
        VideoUploadsViewModel()
    }
    
    @objc func trackVideoUploadsEvent(_ enabled: Bool) {
        viewModel.trackEvent(.videoUploads(enabled))
    }
    
    @objc func trackVideoCodecIsH264Enabled(_ isH264Enabled: Bool) {
        isH264Enabled ? viewModel.trackEvent(.videoCodec(.H264)) : viewModel.trackEvent(.videoCodec(.HEVC))
    }
}
