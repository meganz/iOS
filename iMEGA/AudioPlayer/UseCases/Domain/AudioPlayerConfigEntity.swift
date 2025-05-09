import MEGADomain
import MEGASwift

final class AudioPlayerConfigEntity: @unchecked Sendable {
    enum NodeOriginType: CaseIterable {
        case folderLink
        case fileLink
        case chat
        case unknown
    }
    
    private let _node: Atomic<MEGANode?> = Atomic(wrappedValue: nil)
    private let _allNodes: Atomic<[MEGANode]?> = Atomic(wrappedValue: nil)
    private let audioPlayerHandlerBuilder: any AudioPlayerHandlerBuilderProtocol
    
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
    var node: MEGANode? {
        get {
            _node.wrappedValue
        }
        set {
            _node.mutate { $0 = newValue }
        }
    }

    var playerHandler: any AudioPlayerHandlerProtocol {
        audioPlayerHandlerBuilder.build()
    }
    
    // Playlist for All Nodes from Explorer entry point
    var allNodes: [MEGANode]? {
        get {
            _allNodes.wrappedValue
        }
        set {
            _allNodes.mutate { $0 = newValue }
        }
    }
    
    var isFileLink: Bool {
        fileLink != nil && relatedFiles == nil
    }
    
    var playerType: PlayerType {
        if isFolderLink { return .folderLink }
        if isFileLink { return .fileLink }
        if relatedFiles != nil { return .offline }
        return .default
    }
    
    var nodeOriginType: AudioPlayerConfigEntity.NodeOriginType {
        if isFolderLink { return .folderLink }
        if isFileLink { return .fileLink }
        
        let hasChatIds =
            (messageId != nil && chatId != nil) ||
            (messageId != .invalid && chatId != .invalid)
        
        if hasChatIds { return .chat }
        return .unknown
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
        isFromSharedItem: Bool = false,
        audioPlayerHandlerBuilder: some AudioPlayerHandlerBuilderProtocol = AudioPlayerHandlerBuilder()
    ) {
        self.isFolderLink = isFolderLink
        self.fileLink = fileLink
        self.messageId = messageId
        self.chatId = chatId
        self.relatedFiles = relatedFiles?.filter(\.fileExtensionGroup.isAudio)
        self.shouldResetPlayer = shouldResetPlayer
        self.isFromSharedItem = isFromSharedItem
        self._node.mutate { $0 = node }
        self._allNodes.mutate { $0 = allNodes }
        self.audioPlayerHandlerBuilder = audioPlayerHandlerBuilder
    }
}
