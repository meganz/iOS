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
    
    // Playlist for All Nodes from Explorer entry point
    var allNodes: [MEGANode]?
    
    // Common properties
    var playerHandler: any AudioPlayerHandlerProtocol
    var shouldResetPlayer = false
    
    var isFileLink: Bool {
        fileLink != nil && relatedFiles == nil
    }
    
    var playerType: PlayerType {
        if isFolderLink {
            return .folderLink
        } else if isFileLink {
            return .fileLink
        } else if relatedFiles != nil {
            return .offline
        }
        return .default
    }
    
    enum NodeOriginType: CaseIterable {
        case folderLink
        case fileLink
        case chat
        case unknown
    }
    
    var nodeOriginType: AudioPlayerConfigEntity.NodeOriginType {
        let hasChatIds = (messageId != nil && chatId != nil) || (messageId != .invalid && chatId != .invalid)
        let isChat = hasChatIds && !isFileLink && !isFolderLink
        
        if isFolderLink {
            return .folderLink
        }
        
        if isFileLink {
            return .fileLink
        }
        
        if isChat {
            return .chat
        }
        
        return .unknown
    }
}
