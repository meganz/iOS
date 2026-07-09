import Foundation

enum SleepTimerOption: Hashable, CaseIterable {
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case sixtyMinutes
    case endOfTrack

    var countdownDuration: TimeInterval? {
        switch self {
        case .fiveMinutes: 5 * 60
        case .fifteenMinutes: 15 * 60
        case .thirtyMinutes: 30 * 60
        case .sixtyMinutes: 60 * 60
        case .endOfTrack: nil
        }
    }
}
