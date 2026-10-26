import UIKit

/// Places the bottom overlay (mini player, PSA banner, request status progress bar) for the tab bar state.
/// A vertical tab bar (iPhone Duo) sits at the side and takes no bottom space.
enum BottomOverlayLayout {
    /// The constant for the constraint from the overlay's bottom to the view's bottom.
    static func bottomConstant(
        isTabBarHidden: Bool,
        isTabBarHorizontal: Bool,
        tabBarHeight: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGFloat {
        isTabBarHidden || !isTabBarHorizontal ? -safeAreaBottom : -tabBarHeight
    }

    /// The bottom inset of a list pushed with `hidesBottomBarWhenPushed` when select mode starts or ends.
    /// Returns `nil` with a vertical tab bar, so the list keeps the inset the bottom overlay set.
    static func selectionModeBottomInset(isSelecting: Bool, isTabBarHorizontal: Bool, tabBarHeight: CGFloat) -> CGFloat? {
        guard isTabBarHorizontal else { return nil }
        return isSelecting ? tabBarHeight : 0
    }

    /// Keeps the overlay clear of a vertical tab bar, which sits inside the side safe area.
    /// A horizontal tab bar keeps the overlay at the full view width.
    static func sideInsets(
        isTabBarHidden: Bool,
        isTabBarHorizontal: Bool,
        isRightToLeft: Bool,
        safeArea: UIEdgeInsets
    ) -> NSDirectionalEdgeInsets {
        guard !isTabBarHidden, !isTabBarHorizontal else { return .zero }
        return NSDirectionalEdgeInsets(
            top: 0,
            leading: isRightToLeft ? safeArea.right : safeArea.left,
            bottom: 0,
            trailing: isRightToLeft ? safeArea.left : safeArea.right
        )
    }
}
