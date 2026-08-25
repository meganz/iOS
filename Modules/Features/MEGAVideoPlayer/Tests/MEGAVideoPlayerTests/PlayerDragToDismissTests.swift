import CoreGraphics
@testable import MEGAVideoPlayer
import Testing

struct PlayerDragToDismissTests {
    private static let committedDistance = PlayerDragToDismiss.distanceThreshold
    private static let committedVelocity = PlayerDragToDismiss.velocityThreshold

    @Test(arguments: [
        // Dragged far enough, however slowly the finger was lifted.
        (CGSize(width: 0, height: committedDistance), CGSize.zero, true),
        (CGSize(width: 0, height: committedDistance - 1), CGSize.zero, false),
        // A short but fast flick dismisses too.
        (CGSize(width: 0, height: 20), CGSize(width: 0, height: committedVelocity), true),
        (CGSize(width: 0, height: 20), CGSize(width: 0, height: committedVelocity - 1), false),
        // Down-leaning diagonals still count.
        (CGSize(width: 60, height: committedDistance), CGSize.zero, true),
        (CGSize(width: -60, height: committedDistance), CGSize.zero, true),
        // Flatter than 45 degrees is a swipe across the video area, not a way out.
        (CGSize(width: 400, height: committedDistance), CGSize.zero, false),
        (CGSize(width: -400, height: committedDistance), CGSize(width: 0, height: committedVelocity), false),
        // Upward drags never dismiss, however fast they are.
        (CGSize(width: 0, height: -400), CGSize(width: 0, height: -committedVelocity), false),
        (CGSize(width: 0, height: -20), CGSize(width: 0, height: committedVelocity), false),
        (CGSize.zero, CGSize(width: 0, height: committedVelocity), false)
    ])
    func shouldDismiss(translation: CGSize, velocity: CGSize, expected: Bool) {
        let shouldDismiss = PlayerDragToDismiss.shouldDismiss(
            translation: translation,
            velocity: velocity
        )

        #expect(shouldDismiss == expected)
    }
}
