import Combine
import Foundation

/// Extra bottom padding that bottom-anchored SwiftUI content should add when the system bottom
/// safe area stops accounting for the visible tab bar.
///
/// Content hosted inside the tab bar controller normally relies on the system bottom safe area to
/// stay above the tab bar. That safe area can become stale, for example after a
/// background/foreground cycle combined with the tab bar being hidden and shown again.
///
/// The hosting controller keeps `value` in sync as the difference between the tab bar's real frame
/// height and the current safe area inset. It is `0` while the safe area is correct and grows to
/// cover the missing inset when the safe area is stale.
@MainActor
public final class TabBarSafeAreaInsetCompensation: ObservableObject {
    @Published public var value: CGFloat = 0

    public init() {}
}
