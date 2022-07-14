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
    
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    func downloadToOffline(nodeHandle: MEGAHandle) { }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    func getFilesAndFolders(nodeHandle: MEGAHandle) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    func hasVersions(nodeHandle: MEGAHandle) -> Bool {
        versions
    }
    
    func isDownloaded(nodeHandle: MEGAHandle) -> Bool {
        downloaded
    }
    
    func isInRubbishBin(nodeHandle: MEGAHandle) -> Bool {
        inRubbishBin
    }
    
    func slideShowImages(for node: NodeEntity) -> [NodeEntity] {
        slideShowImages
    }
}
