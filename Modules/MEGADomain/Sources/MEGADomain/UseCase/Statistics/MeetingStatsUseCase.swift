import Foundation

public protocol MeetingStatsUseCaseProtocol {
    func sendEndCallForAllStats()
    func sendEndCallWhenNoParticipantsStats()
    func sendStayOnCallWhenNoParticipantsStats()
    func sendEnableSoundNotificationStats()
    func sendDisableSoundNotificationStats()
    func sendEndCallWhenEmptyCallTimeoutStats()
}

public struct MeetingStatsUseCase<T: StatsRepositoryProtocol>: MeetingStatsUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func sendEndCallForAllStats() {
        repo.sendStatsEvent(.clickMeetingEndCallForAll)
    }
    
    public func sendEndCallWhenNoParticipantsStats() {
        repo.sendStatsEvent(.clickMeetingEndCallInNoParticipantsPopup)
    }
    
    public func sendStayOnCallWhenNoParticipantsStats() {
        repo.sendStatsEvent(.clickMeetingStayOnCallInNoParticipantsPopup)
    }
    
    public func sendEnableSoundNotificationStats() {
        repo.sendStatsEvent(.meetingEnableCallSoundNotifications)
    }
    
    public func sendDisableSoundNotificationStats() {
        repo.sendStatsEvent(.meetingDisableCallSoundNotifications)
    }
    
    public func sendEndCallWhenEmptyCallTimeoutStats() {
        repo.sendStatsEvent(.meetingEndCallWhenEmptyCallTimeout)
    }
}
