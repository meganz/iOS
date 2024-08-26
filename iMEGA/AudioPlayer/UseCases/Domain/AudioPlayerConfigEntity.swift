import MEGADomain
import MEGASwift

final class AudioPlayerConfigEntity: @unchecked Sendable {
    private let _node: Atomic<MEGANode?> = Atomic(wrappedValue: nil)
    private let _allNodes: Atomic<[MEGANode]?> = Atomic(wrappedValue: nil)
    
    // Nodes, File Links, Folder Links
    var node: MEGANode? {
        get {
            _node.wrappedValue
        }
        set {
            _node.mutate { $0 = newValue }
        }
    }
    
    let isFolderLink: Bool
    
    let fileLink: String?
    
    /// Assign these two property for download audio file from chat entry point scenario
    let messageId: HandleEntity?
    let chatId: HandleEntity?
    
    // Offline Files
    let relatedFiles: [String]?
    
    // Playlist
    let parentNode: MEGANode?
    
    // Playlist for All Nodes from Explorer entry point
    var allNodes: [MEGANode]? {
        get {
            _allNodes.wrappedValue
        }
        set {
            _allNodes.mutate { $0 = newValue }
        }
    }
    
    // Common properties
    let playerHandler: any AudioPlayerHandlerProtocol
    let shouldResetPlayer: Bool
    let isFromSharedItem: Bool
    
    init(
        node: MEGANode? = nil,
        isFolderLink: Bool = false,
        fileLink: String? = nil,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        relatedFiles: [String]? = nil,
        parentNode: MEGANode? = nil,
        allNodes: [MEGANode]? = nil,
        playerHandler: some AudioPlayerHandlerProtocol,
        shouldResetPlayer: Bool = false,
        isFromSharedItem: Bool = false
    ) {
        self.isFolderLink = isFolderLink
        self.fileLink = fileLink
        self.messageId = messageId
        self.chatId = chatId
        self.relatedFiles = relatedFiles?.filter(\.fileExtensionGroup.isAudio)
        self.parentNode = parentNode
        self.playerHandler = playerHandler
        self.shouldResetPlayer = shouldResetPlayer
        self.isFromSharedItem = isFromSharedItem
        self._node.mutate { $0 = node }
        self._allNodes.mutate { $0 = allNodes }
    }
    
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
