import Foundation

extension MEGANode {
    
    /// Check whether the receiver is a child node of a given node or equal to that node.
    /// - Parameters:
    ///   - node: The `MEGANode` to check against the receiver.
    ///   - sdk: `MEGASdk` instance which manages both the receiver and the given node.
    /// - Returns: true if the receiver is an immediate or distant child node of the passed node or if passed node is equal to the receiver; otherwise false.
    @objc func isDescendant(of node: MEGANode, in sdk: MEGASdk) -> Bool {
        guard node.handle != handle else {
            return true
        }
        
        guard let parent = sdk.parentNode(for: self) else {
            return false
        }
        
        if parent.handle == node.handle {
            return true
        } else {
            return parent.isDescendant(of: node, in: sdk)
        }
    }
    
    func numberOfLevelsFromRootNode(in sdk: MEGASdk) -> Int {
        guard let parent = sdk.parentNode(for: self) else {
            return 0
        }
        
        return parent.numberOfLevelsFromRootNode(in: sdk) + 1
    }
    
    func filePath(in sdk: MEGASdk,
                  withDelimiter delimiter: String,
                  excludingRootFolder: Bool = false,
                  excludingFileName: Bool = false) -> String {
        guard let parent = sdk.parentNode(for: self) else {
            return excludingRootFolder ? "" : name
        }
        
        guard let name = name else {
            return parent.filePath(in: sdk, withDelimiter: delimiter, excludingRootFolder: excludingRootFolder)
        }
        
        let parentPath = parent.filePath(in: sdk, withDelimiter: delimiter, excludingRootFolder: excludingRootFolder)
        return excludingFileName ? "\(parentPath)"  : (parentPath.isEmpty ? "\(delimiter) \(name)" : "\(parentPath) \(delimiter) \(name)")
    }
    
    @objc func filePathDisplayString(in sdk: MEGASdk, withFont font: UIFont, delimiter: String, maxAvailableWidth: CGFloat) -> String? {
        guard let parent = sdk.parentNode(for: self) else {
            return nil
        }
        
        var path = filePath(in: sdk, withDelimiter: delimiter, excludingRootFolder: !isInShare(), excludingFileName: true)
        
        guard !path.isEmpty else {
            return filePath(in: sdk, withDelimiter: delimiter, excludingFileName: true)
        }
        
        var totalWidthRequired = path.calculateWidth(usingFont: font)
        
        guard totalWidthRequired > maxAvailableWidth, let parentName = parent.name else {
            return path
        }
        
        if !isInShare() {
            path = "\(delimiter) ... \(delimiter) \(parentName)"
            totalWidthRequired = path.calculateWidth(usingFont: font)
            
            guard totalWidthRequired > maxAvailableWidth, parentName.count > 6 else {
                return path
            }
        }
        
        let firstThreeLettersOfFileName = String(parentName[...parentName.index(parentName.startIndex, offsetBy: 2)])
        let lastThreeLettersOfFileName = String(parentName[parentName.index(parentName.endIndex, offsetBy: -3)...])
        
        switch numberOfLevelsFromRootNode(in: sdk) {
        case 0:
            return nil
        case 1:
            return "\(firstThreeLettersOfFileName)...\(lastThreeLettersOfFileName)"
        case 2:
            return "\(delimiter) \(firstThreeLettersOfFileName)...\(lastThreeLettersOfFileName)"
        default:
            return "\(delimiter) ... \(delimiter) \(firstThreeLettersOfFileName)...\(lastThreeLettersOfFileName)"
        }
    }
}


extension Array where Element == MEGANode {
    func contentCounts() -> (fileCount: UInt, folderCount: UInt) {
        reduce(into: (fileCount: 0, folderCount: 0)) { (counts, node) in
            if node.isFile() {
                counts.fileCount += 1
            } else if node.isFolder() {
                counts.folderCount += 1
            }
        }
    }
}
