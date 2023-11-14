import MEGADomain

public final class MockChatNodeRepository: ChatNodeRepositoryProtocol {
    public static let newRepo = MockChatNodeRepository()
    
    private let node: NodeEntity?
    
    public init(
        node: NodeEntity? = nil
    ) {
        self.node = node
    }
    
    public func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity? {
        node
    }
}
