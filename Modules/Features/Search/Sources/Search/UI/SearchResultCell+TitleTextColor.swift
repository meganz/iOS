import MEGADesignToken
import SwiftUI

struct TitleTextColor: ViewModifier {
    let hasVibrantTitle: Bool
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(titleTextColor(hasVibrantTitle: hasVibrantTitle))
    }
    
    private func titleTextColor(hasVibrantTitle: Bool) -> Color {
        if hasVibrantTitle {
            return TokenColors.Text.error.swiftUI
        } else {
            return TokenColors.Text.primary.swiftUI
        }
    }
}

extension View {
    func titleTextColor(
        hasVibrantTitle: Bool
    ) -> some View {
        modifier(
            TitleTextColor(
                hasVibrantTitle: hasVibrantTitle
            )
        )
    }
}
