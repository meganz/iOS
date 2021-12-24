@testable import MEGA

final class MockNodeActionUseCase: NodeActionUseCaseProtocol {
    var nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown
    
    var labelString: String = ""
    
    var filesAndFolders = (0, 0)
    var versions: Bool = false
    var downloaded: Bool = false
    
    func nodeAccessLevel() -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    func downloadToOffline() { }
    
    func labelString(label: NodeLabelTypeModel) -> String {
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
}
