import MEGAAppPresentation
import SwiftUI
import UIKit

public extension View {
    /// Calculates the bottom padding to avoid the Liquid Glass TabBar.
    ///
    /// When a page uses `ignoresSafeArea(.bottom)` to adapt to liquid glass, bottom UI components may be obscured by the MainTabBar.
    /// This method returns appropriate bottom padding when the Liquid Glass feature is enabled to ensure
    /// UI components remain visible and are not covered by the MainTabBar.
    ///
    /// - Parameters:
    ///   - isMediaRevampEnabled: Whether the media revamp remote feature flag is enabled
    ///   - additionalPadding: Additional padding to add on top of the safe area inset. Defaults to 44.
    /// - Returns: The bottom padding value. Returns 0 if Liquid Glass is not enabled or media revamp is disabled
    func liquidGlassTabBarAvoidancePadding(
        isMediaRevampEnabled: Bool,
        additionalPadding: CGFloat? = nil
    ) -> CGFloat {
        let isLiquidGlassSupported = if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
        guard isLiquidGlassSupported,
              isMediaRevampEnabled else {
            return 0
        }
        let bottomInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
        let padding = additionalPadding ?? (UIDevice.current.userInterfaceIdiom == .pad ? 56 : 44)
        return bottomInset + padding
    }
}
