
import Foundation

extension MEGANode {
    
    @objc func filePath(withDelimeter delimeter: String,
                  sdk: MEGASdk,
                  includeRootFolderName: Bool,
                  excludeFileName: Bool) -> String {
        guard let parent = sdk.parentNode(for: self) else {
            return includeRootFolderName ? name : ""
        }
        
        var path = parent.filePath(withDelimeter: delimeter,
                                   sdk: sdk,
                                   includeRootFolderName: includeRootFolderName,
                                   excludeFileName: false)
        
        if let name = name, !excludeFileName {
            path += "\(delimeter)\(name)"
        }
        
        return path
    }
}
