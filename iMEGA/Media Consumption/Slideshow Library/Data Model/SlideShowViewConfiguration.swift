import Foundation

enum SlideShowPlayingOrder {
    case shuffled
    case newest
    case oldest
}

enum SlideShowTimeIntervalOption {
    case slow
    case normal
    case fast
    
    var value: Double {
        switch self {
        case .slow: return 8
        case .normal: return 4
        case .fast: return 2
        }
    }
}

struct SlideShowViewConfiguration: Equatable {
    var playingOrder: SlideShowPlayingOrder
    var timeIntervalForSlideInSeconds: SlideShowTimeIntervalOption
    var isRepeat: Bool
    var includeSubfolders: Bool
}
