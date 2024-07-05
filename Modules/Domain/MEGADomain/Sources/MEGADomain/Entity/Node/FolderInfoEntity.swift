public struct FolderInfoEntity: Equatable, Sendable {
    public let versions: Int
    public let files: Int
    public let folders: Int
    public let currentSize: Int64
    public let versionsSize: Int64

    public init(versions: Int, files: Int, folders: Int, currentSize: Int64, versionsSize: Int64) {
        self.versions = versions
        self.files = files
        self.folders = folders
        self.currentSize = currentSize
        self.versionsSize = versionsSize
    }
}
