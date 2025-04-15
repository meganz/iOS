import UIKit

/// Protocol for UIViewControllers that should display the mini-player along with the bottom overlay.
/// Conforming to this protocol indicates that the mini-player must be shown in the current view. If a view controller conforms the AudioPlayerPresenterProtocol,
/// the mini-player will be displayed. Otherwise, even if other bottom overlay views are presented, the mini-player should remain hidden. This is useful in cases
/// such as the Photos section, where the bottom overlay is used but the mini-player should no be shown
@objc public protocol AudioPlayerPresenterProtocol: BottomOverlayPresenterProtocol {}

@objc public protocol BottomOverlayPresenterProtocol where Self: UIViewController {
    /// Updates the content inset of the displayed screen.
    /// This method adjusts the bottom inset of the screen's content to ensure that it is not obscured by the views shown in the BottomOverlay.
    /// Use this function to apply a new inset height that compensates for any overlay elements.
    /// - Parameter height: The new height value to be applied as the bottom content inset of the displayed screen view.
    func updateContentView(_ height: CGFloat)
    /// Checks if the content view of the current view has been previously updated.
    /// This method returns `true` if the content inset has already been updated for the current view, allowing the system to reduce redundant
    /// updates and avoid unnecessary recalculations of the content inset.
    /// - Returns: A Boolean value indicating whether the content view has been updated.
    func hasUpdatedContentView() -> Bool
}
