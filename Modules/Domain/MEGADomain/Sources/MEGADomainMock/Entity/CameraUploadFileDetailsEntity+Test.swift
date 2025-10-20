import MEGADomain

public extension CameraUploadFileDetailsEntity {
    init(
        localIdentifier: String,
        fileName: String = "",
        fileExtension: String = "",
        isTesting: Bool = true
    ) {
        self.init(
            localIdentifier: localIdentifier,
            fileName: fileName,
            fileExtension: fileExtension)
    }
}
