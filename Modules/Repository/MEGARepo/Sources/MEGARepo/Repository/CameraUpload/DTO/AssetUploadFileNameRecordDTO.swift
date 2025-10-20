public struct AssetUploadFileNameRecordDTO: Sendable, Hashable {
    public let localIdentifier: String
    public let localUniqueFileName: String?
    public let fileExtension: String?
    
    public init(localIdentifier: String, localUniqueFileName: String?, fileExtension: String?) {
        self.localIdentifier = localIdentifier
        self.localUniqueFileName = localUniqueFileName
        self.fileExtension = fileExtension
    }
}
