
import Foundation

extension MEGANode {
    
    /// Return the file path relative to the root directory of the receiver seperated by the delimeter string.
    /// - Parameters:
    ///   - withDelimeter: This string will be used as the seperator between the two nodes names in the returned string.
    ///   - sdk: `MEGASdk` instance which manages both the receiver and the given node.
    ///   - includeRootFolderName: The returned string will contain the root folder name if this parameter is true.
    ///   - excludeFileName: The returned string will not contain the name of the receiver if this parameter is true.
    /// - Returns: The string that contains the file path relative to the root directory of the receiver.
    @objc func filePath(withDelimeter delimeter: String,
                  sdk: MEGASdk,
                  includeRootFolderName: Bool,
                  excludeFileName: Bool) -> String {
        guard let parent = sdk.parentNode(for: self) else {
            return (includeRootFolderName && !excludeFileName) ? name : ""
        }
        
        var path = parent.filePath(withDelimeter: delimeter,
                                   sdk: sdk,
                                   includeRootFolderName: includeRootFolderName,
                                   excludeFileName: false)
        
        if let name = name, !excludeFileName {
            path += path.isEmpty ? name : "\(delimeter)\(name)"
        }
        
        return path
    }
}
