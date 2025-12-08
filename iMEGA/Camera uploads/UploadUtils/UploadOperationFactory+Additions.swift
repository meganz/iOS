import MEGAAppPresentation

extension UploadOperationFactory {
    @objc static func makeCameraUploadTransferProgressRepository() -> CameraUploadTransferProgressOCRepository? {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCameraUploadBreakdown) else { return nil }
        return CameraUploadTransferProgressOCRepository()
    }
}
