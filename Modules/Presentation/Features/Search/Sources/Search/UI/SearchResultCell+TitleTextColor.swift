import SwiftUI

struct TitleTextColor: ViewModifier {
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    let colorAssets: SearchConfig.ColorAssets
    let hasVibrantTitle: Bool
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(titleTextColor(hasVibrantTitle: hasVibrantTitle))
    }
    
    private func titleTextColor(hasVibrantTitle: Bool) -> Color {
        if hasVibrantTitle {
            if colorScheme == .light {
                if colorSchemeContrast == .increased {
                    return colorAssets.CE0A11
                } else {
                    return colorAssets.F30C14
                }
            } else {
                if colorSchemeContrast == .increased {
                    return colorAssets.F95C61
                } else {
                    return colorAssets.F7363D
                }
            }
        } else {
            return .primary
        }
    }
}

extension View {
    func titleTextColor(
        colorAssets: SearchConfig.ColorAssets,
        hasVibrantTitle: Bool
    ) -> some View {
        modifier(
            TitleTextColor(
                colorAssets: colorAssets,
                hasVibrantTitle: hasVibrantTitle
            )
        )
    }
}
