import Foundation

/// User-facing repeat behavior for the audio player
enum RepeatMode: CaseIterable, Hashable {
    case off
    case all
    case one

    /// Next mode in the tap-to-cycle order: off → all → one → off
    var next: RepeatMode {
        switch self {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }
}
