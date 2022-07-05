import Foundation
@testable import MEGA

struct MockNodeActionRepository: NodeActionRepositoryProtocol {
    static var newRepo: MockNodeActionRepository {
        MockNodeActionRepository()
    }
    
    var nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown
    var labelString: String = ""
    
    var filesAndFolders = (0, 0)
    var versions: Bool = false
    var downloaded: Bool = false
    var inRubbishBin: Bool = false
    var images: [NodeEntity] = []
    
    func nodeAccessLevel() -> MEGA.NodeAccessTypeEntity {
        nodeAccessLevelVariable
    }
    
    func labelString(label: MEGA.NodeLabelTypeEntity) -> String {
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
    
    func images(for parentNode: NodeEntity) -> [NodeEntity] {
        images
    }
    
    func images(for parentHandle: MEGAHandle) -> [NodeEntity] {
        images
    }
}
