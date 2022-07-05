protocol NodeActionRepositoryProtocol: RepositoryProtocol {
    func nodeAccessLevel() -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions() -> Bool
    func isDownloaded() -> Bool
    func isInRubbishBin() -> Bool
    func images(for parentNode: NodeEntity) -> [NodeEntity]
    func images(for parentHandle: MEGAHandle) -> [NodeEntity]
}
