@testable import MEGA

final class MockNodeActionUseCase: NodeActionUseCaseProtocol {
    var nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown
    var labelString: String = ""
    
    var filesAndFolders = (0, 0)
    var versions: Bool = false
    var downloaded: Bool = false
    var inRubbishBin: Bool = false
    let slideShowImages: [NodeEntity]
    
    init(slideShowImages: [NodeEntity] = []) {
        self.slideShowImages = slideShowImages
    }
    
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
    
    func slideShowImages(for node: NodeEntity) -> [NodeEntity] {
        slideShowImages
    }
}
