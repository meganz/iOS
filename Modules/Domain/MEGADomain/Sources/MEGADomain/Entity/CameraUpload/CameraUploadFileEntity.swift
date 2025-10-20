public struct CameraUploadFileDetailsEntity: Sendable, Hashable {
    public let localIdentifier: String
    public let fileName: String
    public let fileExtension: String
    
    public init(
        localIdentifier: String,
        fileName: String,
        fileExtension: String
    ) {
        self.localIdentifier = localIdentifier
        self.fileName = fileName
        self.fileExtension = fileExtension
    }
}
