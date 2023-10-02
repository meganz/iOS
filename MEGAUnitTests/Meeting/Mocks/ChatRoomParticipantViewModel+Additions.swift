@testable import MEGA
import MEGADomain
import MEGADomainMock

extension ChatRoomParticipantViewModel {
    convenience init(
        router: some MeetingInfoRouting = MockMeetingInfoRouter(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        chatParticipantId: MEGAHandle = .invalidHandle,
        chatRoom: ChatRoomEntity = .init(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            chatUseCase: chatUseCase,
            chatParticipantId: chatParticipantId,
            chatRoom: chatRoom
        )
    }
}
