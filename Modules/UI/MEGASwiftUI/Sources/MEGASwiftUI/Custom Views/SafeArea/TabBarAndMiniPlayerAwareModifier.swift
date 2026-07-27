import SwiftUI

struct TabBarAndMiniPlayerAwareModifier: ViewModifier {
    @EnvironmentObject private var miniPlayerVisibility: MiniPlayerVisibility
    @EnvironmentObject private var tabBarSafeAreaInsetCompensation: TabBarSafeAreaInsetCompensation

    func body(content: Content) -> some View {
        content
            .padding(.bottom, miniPlayerVisibility.height + tabBarSafeAreaInsetCompensation.value)
    }
}

public extension View {
    /// Adds bottom padding for the mini player height plus any tab bar safe area inset that has gone
    /// stale (see `TabBarSafeAreaInsetCompensation`), keeping bottom anchored content visible.
    func tabBarAndMiniPlayerAware() -> some View {
        modifier(TabBarAndMiniPlayerAwareModifier())
    }
}
