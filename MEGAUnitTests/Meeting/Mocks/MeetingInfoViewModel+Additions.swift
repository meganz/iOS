@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation

extension MeetingInfoViewModel {
    convenience init(
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        router: some MeetingInfoRouting = MockMeetingInfoRouter(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        chatLinkUseCase: some ChatLinkUseCaseProtocol = MockChatLinkUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        isTesting: Bool = true
    ) {
        self.init(
            scheduledMeeting: scheduledMeeting,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            chatLinkUseCase: chatLinkUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
    }
}
