import Foundation

enum PlaybackSpeed: Float, CaseIterable {
    case quarter = 0.25
    case half = 0.5
    case threeQuarter = 0.75
    case normal = 1.0
    case oneQuarter = 1.25
    case oneHalf = 1.5
    case oneThreeQuarter = 1.75
    case double = 2.0

    var displayText: String {
        switch self {
        case .quarter: "0.25x"
        case .half: "0.5x"
        case .threeQuarter: "0.75x"
        case .normal: "1x"
        case .oneQuarter: "1.25x"
        case .oneHalf: "1.5x"
        case .oneThreeQuarter: "1.75x"
        case .double: "2x"
        }
    }
    
    func next() -> PlaybackSpeed {
        switch self {
        case .quarter: .half
        case .half: .threeQuarter
        case .threeQuarter: .normal
        case .normal: .oneQuarter
        case .oneQuarter: .oneHalf
        case .oneHalf: .oneThreeQuarter
        case .oneThreeQuarter: .double
        case .double: .quarter
        }
    }
}
