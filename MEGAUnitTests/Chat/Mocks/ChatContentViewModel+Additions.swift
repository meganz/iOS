@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock

extension ChatContentViewModel {
    convenience init(
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        isTesting: Bool = true
    ) {
        self.init(
            chatRoom: chatRoom,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            featureFlagProvider: featureFlagProvider
        )
    }
}
