import Foundation

enum SleepTimerState: Equatable {
    case inactive
    case countdown(deadline: Date)
    case endOfTrack

    var isActive: Bool { self != .inactive }
}
