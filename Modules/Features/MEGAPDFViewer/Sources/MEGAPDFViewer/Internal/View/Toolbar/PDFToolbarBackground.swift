import MEGADesignToken
import SwiftUI

private struct TransparentLiquidGlassOrSolidOtherwiseToolbarBackground: ViewModifier {
    let placement: ToolbarPlacement

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.toolbarBackgroundVisibility(.hidden, for: placement)
        } else {
            content
                .toolbarBackground(.visible, for: placement)
                .toolbarBackground(TokenColors.Background.surface1.swiftUI, for: placement)
        }
    }
}

extension View {
    func transparentLiquidGlassOrSolidOtherwiseToolbarBackground(for placement: ToolbarPlacement) -> some View {
        modifier(TransparentLiquidGlassOrSolidOtherwiseToolbarBackground(placement: placement))
    }
}
