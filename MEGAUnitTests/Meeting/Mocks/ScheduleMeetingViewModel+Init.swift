@testable import MEGA
import MEGADomain

extension ScheduleMeetingViewModel {
    convenience init(
        router: ScheduleMeetingRouting = MockScheduleMeetingRouter(),
        rules: ScheduledMeetingRulesEntity = ScheduledMeetingRulesEntity(frequency: .invalid),
        scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        chatLinkUseCase: ChatLinkUseCaseProtocol = MockChatLinkUseCase(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        isTesting: Bool = true
    ) {
        self.init(router: router, rules: rules, scheduledMeetingUseCase: scheduledMeetingUseCase, chatLinkUseCase: chatLinkUseCase, chatRoomUseCase: chatRoomUseCase)
    }
}
