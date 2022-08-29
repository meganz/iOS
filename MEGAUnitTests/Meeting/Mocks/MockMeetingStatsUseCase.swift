@testable import MEGA
import MEGADomain

final class MockMeetingStatsUseCase: MeetingStatsUseCaseProtocol {
    private(set) var sendEndCallForAllStats_calledTimes = 0

    func sendEndCallForAllStats() {
        sendEndCallForAllStats_calledTimes += 1
    }
    
    func sendEndCallWhenNoParticipantsStats() {}
    func sendStayOnCallWhenNoParticipantsStats() {}
    func sendEnableSoundNotificationStats() {}
    func sendDisableSoundNotificationStats() {}
    func sendEndCallWhenEmptyCallTimeoutStats() {}
}
