public struct CameraUploadTaskInfoEntity: Sendable {
    public let localIdentifier: CameraUploadLocalIdentifierEntity
    public let chunkIndex: Int
    public let totalChunks: Int
    
    public init(localIdentifier: CameraUploadLocalIdentifierEntity, chunkIndex: Int, totalChunks: Int) {
        self.localIdentifier = localIdentifier
        self.chunkIndex = chunkIndex
        self.totalChunks = totalChunks
    }
}
