import MEGADomain

extension MEGAImagePickerController {
    @PreferenceWrapper(key: .isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
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
}
