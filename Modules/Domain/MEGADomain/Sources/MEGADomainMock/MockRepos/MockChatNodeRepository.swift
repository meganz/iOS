import MEGADomain

public final class MockChatNodeRepository: ChatNodeRepositoryProtocol {
    public static let newRepo = MockChatNodeRepository()
    
    private let node: NodeEntity?
    private let size: UInt64?
    
    public init(
        node: NodeEntity? = nil,
        size: UInt64? = nil
    ) {
        self.node = node
        self.size = size
    }
    
    public func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity? {
        node
    }
    
    public func sizeForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> UInt64? {
        size
    }
}
