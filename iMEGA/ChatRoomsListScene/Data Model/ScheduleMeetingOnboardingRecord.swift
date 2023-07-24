import Foundation
import MEGADomain

enum ScheduledMeetingOnboardingTip {
    case initial
    case createMeeting
    case recurringOrStartMeeting
    case startMeeting
    case recurringMeeting
    case showedAll
}

struct ScheduledMeetingOnboardingTipRecord {
    let currentTip: ScheduledMeetingOnboardingTip
}

extension ScheduledMeetingOnboardingTip {
    func toScheduledMeetingOnboardingTipType() -> ScheduledMeetingOnboardingTipType {
        switch self {
        case .initial: return .initial
        case .createMeeting: return .createMeeting
        case .recurringOrStartMeeting: return .recurringOrStartMeeting
        case .startMeeting: return .startMeeting
        case .recurringMeeting: return .recurringMeeting
        case .showedAll: return .showedAll
        }
    }
    
    static func toScheduledMeetingOnboardingTip(from scheduledMeetingOnboardingTipType: ScheduledMeetingOnboardingTipType) -> ScheduledMeetingOnboardingTip {
        switch scheduledMeetingOnboardingTipType {
        case .initial: return .initial
        case .createMeeting: return .createMeeting
        case .recurringOrStartMeeting: return .recurringOrStartMeeting
        case .startMeeting: return .startMeeting
        case .recurringMeeting: return .recurringMeeting
        case .showedAll: return .showedAll
        }
    }
}
