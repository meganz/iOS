import Foundation
import MEGASdk

public extension Array where Element: MEGANode {
    func contentCounts() -> (fileCount: UInt, folderCount: UInt) {
        reduce(into: (fileCount: 0, folderCount: 0)) { (counts, node) in
            if node.isFile() {
                counts.fileCount += 1
            } else if node.isFolder() {
                counts.folderCount += 1
            }
        }
    }
    
    func folderNodeList() -> [MEGANode] {
        filter { $0.isFolder() }
    }
    
    func fileNodeList() -> [MEGANode] {
        filter { $0.isFile() }
    }
    
    func multiMediaNodeList() -> [MEGANode] {
        filter { $0.name?.fileExtensionGroup.isVisualMedia == true }
    }
}
