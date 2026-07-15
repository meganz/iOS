import MEGADesignToken
import SwiftUI

/// A full-width primary button filled with `TokenColors.Button.brand`.
///
/// `MEGAButton` hardcodes its background per `MEGAButtonType` and exposes no brand
/// variant, so promotional CTAs that must use the brand color rely on this style.
/// The metrics mirror `MEGAButton`'s primary look so it stays visually consistent.
struct BrandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.bold())
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(TokenSpacing._4)
            .frame(minHeight: 48)
            .background(TokenColors.Button.brand.swiftUI)
            .foregroundStyle(TokenColors.Text.onColor.swiftUI)
            .cornerRadius(TokenRadius.medium)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#Preview {
    Button("Get Pro I", action: {})
        .buttonStyle(BrandButtonStyle())
        .padding()
}
