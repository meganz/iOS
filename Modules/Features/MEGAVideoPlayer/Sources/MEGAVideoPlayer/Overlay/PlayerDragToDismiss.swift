import CoreGraphics

/// Decides whether a drag on the video area is a request to leave the player
enum PlayerDragToDismiss {
    /// Downward distance, in points, that dismisses the player when the finger is lifted.
    static let distanceThreshold: CGFloat = 120
    /// Downward speed, in points per second, that dismisses regardless of the distance covered,
    /// so a short flick works as well as a long drag.
    static let velocityThreshold: CGFloat = 900

    static func shouldDismiss(translation: CGSize, velocity: CGSize) -> Bool {
        // Only downward, vertical-dominant drags dismiss: anything flatter is a swipe across
        // the video area rather than a way out of the player.
        guard translation.height > 0, translation.height > abs(translation.width) else {
            return false
        }

        return velocity.height >= velocityThreshold || translation.height >= distanceThreshold
    }
}
