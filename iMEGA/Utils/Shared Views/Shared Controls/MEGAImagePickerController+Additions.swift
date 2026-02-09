import MEGADomain
import MEGAPreference

extension MEGAImagePickerController {
    @PreferenceWrapper(key: PreferenceKeyEntity.isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var isSaveMediaCapturedToGalleryEnabled: Bool
    
    @objc func hasSetIsSaveMediaCapturedToGalleryEnabled() -> Bool {
        Self.$isSaveMediaCapturedToGalleryEnabled.existed
    }
    
    @objc func setIsSaveMediaCapturedToGalleryEnabled(_ enabled: Bool) {
        Self.isSaveMediaCapturedToGalleryEnabled = enabled
    }
    
    @objc func getIsSaveMediaCapturedToGalleryEnabled() -> Bool {
        Self.isSaveMediaCapturedToGalleryEnabled
    }
    
    @objc func cancellableTransfer(parentNode: MEGANode, localFileURL: URL?) -> CancellableTransfer {
        let uploadOptions = UploadOptionsEntity(
            pitagTrigger: .camera,
            pitagTarget: parentNode.isInShare() ? .incomingShare : .cloudDrive
        )
        return CancellableTransfer(
            handle: MEGAInvalidHandle,
            parentHandle: parentNode.handle,
            localFileURL: localFileURL,
            type: .upload,
            uploadOptions: uploadOptions
        )
    }
}
