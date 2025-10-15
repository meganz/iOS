import MEGAAppPresentation

extension UploadOperationFactory {
    @objc static func makeCameraUploadTransferProgressRepository() -> CameraUploadTransferProgressOCRepository? {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cameraUploadProgress) else { return nil }
        return CameraUploadTransferProgressOCRepository()
    }
}
