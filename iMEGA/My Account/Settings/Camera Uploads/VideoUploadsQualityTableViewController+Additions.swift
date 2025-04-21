extension VideoUploadsQualityTableViewController {
    @objc func makeViewModel() -> VideoUploadsViewModel {
        VideoUploadsViewModel()
    }
    
    @objc func trackVideoQualityEvent(_ qualityValue: Int) {
        guard let quality = VideoQuality(rawValue: qualityValue) else { return }
        switch quality {
        case .low: viewModel.trackEvent(.videoQuality(.low))
        case .medium: viewModel.trackEvent(.videoQuality(.medium))
        case .high: viewModel.trackEvent(.videoQuality(.high))
        case .original: viewModel.trackEvent(.videoQuality(.original))
        }
    }
}
