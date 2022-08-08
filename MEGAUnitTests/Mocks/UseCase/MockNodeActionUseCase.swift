@testable import MEGA
import MEGADomain

final class MockNodeActionUseCase: NodeActionUseCaseProtocol {
    var nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown
    var labelString: String = ""
    
    var filesAndFolders = (0, 0)
    var versions: Bool = false
    var downloaded: Bool = false
    var inRubbishBin: Bool = false
    
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    func downloadToOffline(nodeHandle: HandleEntity) { }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    func hasVersions(nodeHandle: HandleEntity) -> Bool {
        versions
    }
    
    func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        downloaded
    }
    
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        inRubbishBin
    }
}
