import Foundation

extension FileManager {
    @objc func mnz_folderContentStat(pathForItem: String) -> FolderContentStat {
        let folderContentStat = FolderContentStat()
        var folders = 0
        var files = 0
        if let dc = try? self.contentsOfDirectory(atPath: pathForItem) {
            for file in dc {
                var isDirectory:ObjCBool = false
                let path = pathForItem.append(pathComponent: file)
                if path.lowercased() != "mega" {
                    self.fileExists(atPath: path, isDirectory: &isDirectory)
                    if isDirectory.boolValue {
                        folders += 1
                    } else {
                        files += 1
                    }
                }
            }
        }
        
        folderContentStat.fileCount = files
        folderContentStat.folderCount = folders
        return folderContentStat
    }
}
