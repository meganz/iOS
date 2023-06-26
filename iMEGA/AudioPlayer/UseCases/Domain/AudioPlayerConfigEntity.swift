import MEGADomain

struct AudioPlayerConfigEntity {
    // Nodes, File Links, Folder Links
    var node: MEGANode?
    var isFolderLink = false
    
    var fileLink: String?
    
    /// Assign these two property for download audio file from chat entry point scenario
    var messageId: HandleEntity?
    var chatId: HandleEntity?
    
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
