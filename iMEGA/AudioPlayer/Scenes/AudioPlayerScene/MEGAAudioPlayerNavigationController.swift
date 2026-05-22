import MEGAAudioPlayer
import UIKit

/// Navigation container for the revamped audio player modal. Locks the modal
/// to portrait orientation — the audio player is portrait-only by design
/// (IOS-11903), since landscape provides no content benefit for audio playback
/// and mainstream music apps follow the same pattern.
///
/// Lives in the host target (rather than `MEGAAudioPlayer` package) so it can
/// inherit from `MEGANavigationController` without sinking that ObjC class into
/// a Swift Package — see IOS-11903 for the rationale.
final class MEGAAudioPlayerNavigationController: MEGANavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }

    /// Factory matching the shape `MEGAAudioPlayerViewRouter.NavigationFactory`
    /// expects, so the 4 host call sites stay one-liners — mirrors
    /// `MEGAAudioPlayerActionsHandler.make()`.
    static func make() -> MEGAAudioPlayerViewRouter.NavigationFactory {
        { MEGAAudioPlayerNavigationController(rootViewController: $0) }
    }
}
