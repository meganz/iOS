
struct AudioPlayerConfigEntity {
    // Nodes, File Links, Folder Links
    var node: MEGANode? = nil
    var isFolderLink = false
    
    var fileLink: String? = nil
    
    // Offline Files
    var relatedFiles: [String]? = nil
    
    // Playlist
    var parentNode: MEGANode? = nil
    
    // Common properties
    var playerHandler: AudioPlayerHandlerProtocol
    var shouldResetPlayer = false
    
    lazy var isFileLink: Bool = {
       fileLink != nil && relatedFiles == nil
    }()
    
    lazy var playerType: PlayerType = {
        if isFolderLink {
            return .folderLink
        } else if isFileLink {
            return .fileLink
        } else if relatedFiles != nil {
            return .offline
        }
        return .default
    }()
}
