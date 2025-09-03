import MEGADomain
import MEGASwift

struct AudioPlayerConfigEntity: Sendable {
    enum NodeOriginType: CaseIterable {
        case folderLink
        case fileLink
        case chat
        case unknown
    }
    
    let isFolderLink: Bool
    let fileLink: String?
    
    /// Assign these two property for download audio file from chat entry point scenario
    let messageId: HandleEntity?
    let chatId: HandleEntity?
    
    /// Offline Files
    let relatedFiles: [String]?
    
    let shouldResetPlayer: Bool
    let isFromSharedItem: Bool
    
    /// Nodes, File Links, Folder Links
    let node: MEGANode?
    
    // Playlist for All Nodes from Explorer entry point
    let allNodes: [MEGANode]?
    
    var isFileLink: Bool {
        fileLink != nil && relatedFiles == nil
    }
    
    var playerType: PlayerType {
        return switch true {
        case isFolderLink: .folderLink
        case isFileLink: .fileLink
        case relatedFiles != nil: .offline
        default: .default
        }
    }

    var nodeOriginType: AudioPlayerConfigEntity.NodeOriginType {
        return switch true {
        case isFolderLink: .folderLink
        case isFileLink: .fileLink
        case hasValidChatIds: .chat
        default: .unknown
        }
    }
    
    private var hasValidChatIds: Bool {
        (messageId != nil && chatId != nil) ||
        (messageId != .invalid && chatId != .invalid)
    }
    
    init(
        node: MEGANode? = nil,
        isFolderLink: Bool = false,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        allNodes: [MEGANode]? = nil,
        shouldResetPlayer: Bool = false,
        isFromSharedItem: Bool = false
    ) {
        self.isFolderLink = isFolderLink
        self.fileLink = fileLink
        self.messageId = messageId
        self.chatId = chatId
        self.relatedFiles = relatedFiles?.filter(\.fileExtensionGroup.isAudio)
        self.shouldResetPlayer = shouldResetPlayer
        self.isFromSharedItem = isFromSharedItem
        self.node = node
        self.allNodes = allNodes
    }
}
