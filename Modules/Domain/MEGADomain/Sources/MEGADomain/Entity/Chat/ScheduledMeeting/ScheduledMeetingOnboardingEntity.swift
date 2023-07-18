import Foundation

public enum ScheduledMeetingOnboardingTipType: String, Codable, Sendable {
    case initial
    case createMeeting
    case startMeeting
    case recurringMeeting
    case showedAll
}

public struct ScheduledMeetingOnboardingRecord: Codable, Sendable {
    public let currentTip: ScheduledMeetingOnboardingTipType
    
    public init(currentTip: ScheduledMeetingOnboardingTipType) {
        self.currentTip = currentTip
    }
}

public struct ScheduledMeetingOnboardingIos: Codable, Sendable {
    public let record: ScheduledMeetingOnboardingRecord
    
    public init(record: ScheduledMeetingOnboardingRecord) {
        self.record = record
    }
}

public struct ScheduledMeetingOnboardingEntity: Codable, Sendable {
    public let ios: ScheduledMeetingOnboardingIos
    
    public init(ios: ScheduledMeetingOnboardingIos) {
        self.ios = ios
    }
    
    public func update(record: ScheduledMeetingOnboardingRecord) -> ScheduledMeetingOnboardingEntity {
        ScheduledMeetingOnboardingEntity(ios: ScheduledMeetingOnboardingIos(record: record))
    }
}
