@testable import MEGA

final class MockNodeActionUseCase: NodeActionUseCaseProtocol {
    var nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown
    
    var labelString: String = ""
    
    var filesAndFolders = (0, 0)
    var versions: Bool = false
    var downloaded: Bool = false
    var inRubbishBin: Bool = false
    
    func nodeAccessLevel() -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    func downloadToOffline() { }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    func hasVersions() -> Bool {
        versions
    }
    
    func isDownloaded() -> Bool {
        downloaded
    }
    
    func isInRubbishBin() -> Bool {
        inRubbishBin
    }
}
