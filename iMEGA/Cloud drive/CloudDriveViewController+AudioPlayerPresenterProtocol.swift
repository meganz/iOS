extension CloudDriveViewController: AudioPlayerPresenterProtocol {
    
    func updateContentView(_ height: CGFloat) {
        Task { @MainActor in
            additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
        }
    }
}
