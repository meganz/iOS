
struct AudioPlayerConfigEntity {
    // Nodes, File Links, Folder Links
    var node: MEGANode?
    var isFolderLink = false
    
    var fileLink: String?
    
    // Offline Files
    var relatedFiles: [String]?
    
    // Playlist
    var parentNode: MEGANode?
    
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
