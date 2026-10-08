import MEGADesignToken
import SwiftUI

extension View {
    /// Liquid Glass on iOS 26. Older systems get the Figma fill: material, 12% surface tint and two shadows.
    @ViewBuilder
    func toolbarGlass(in shape: some Shape) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(TokenColors.Background.surface1.swiftUI.opacity(FallbackGlass.tintOpacity))
                }
                .shadow(color: .black.opacity(FallbackGlass.shadowOpacity), radius: FallbackGlass.shadowRadius, y: FallbackGlass.shadowY)
                .shadow(color: .black.opacity(FallbackGlass.softShadowOpacity), radius: FallbackGlass.softShadowRadius, y: FallbackGlass.shadowY)
            }
        }
    }
}

/// The design's glass look before iOS 26. No opacity or shadow token exists.
private enum FallbackGlass {
    static let tintOpacity = 0.12
    static let shadowOpacity = 0.12
    static let shadowRadius: CGFloat = 20
    static let softShadowOpacity = 0.08
    static let softShadowRadius: CGFloat = 6
    static let shadowY: CGFloat = 8
}
