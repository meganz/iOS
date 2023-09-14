extension CloudDriveViewController: AudioPlayerPresenterProtocol {
    
    func updateContentView(_ height: CGFloat) {
        var adjustedSafeAreaInset = additionalSafeAreaInsets
        adjustedSafeAreaInset.bottom = height
        self.additionalSafeAreaInsets = adjustedSafeAreaInset
    }
}
