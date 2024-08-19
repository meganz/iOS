import MEGADomain
import MEGASwift

public struct ChatRoomUpdateRepository: ChatRoomUpdateRepositoryProtocol {
    private let chatRoomUpdateProvider: any ChatRoomUpdateProviderProtocol

    public init(chatRoomUpdateProvider: some ChatRoomUpdateProviderProtocol) {
        self.chatRoomUpdateProvider = chatRoomUpdateProvider
    }
    
    public var chatRoomUpdate: AnyAsyncSequence<ChatRoomEntity> {
        chatRoomUpdateProvider.chatRoomUpdate
    }
}
