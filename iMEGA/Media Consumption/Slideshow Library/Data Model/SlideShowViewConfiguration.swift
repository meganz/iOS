import Foundation

enum SlideShowPlayingOrder {
    case shuffled
    case newest
    case oldest
}

struct SlideShowViewConfiguration {
    var playingOrder: SlideShowPlayingOrder
    var timeIntervalForSlideInSeconds: Double
}
