import MEGADesignToken
import MEGAUIComponent
import SwiftUI

/// A full-width button filled with `TokenColors.Button.brand`.
///
/// `MEGAButton` hardcodes its background per `MEGAButtonType` and exposes no brand
/// variant, so promotional CTAs that must use the brand color use this instead.
/// The metrics and `state` handling mirror `MEGAButton` so the two stay consistent.
struct BrandButton: View {
    let title: String
    var state: MEGAButtonState = .default
    var accessibilityIdentifier: String?
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(Style(state: state))
            .disabled(!state.isEnabled)
            .accessibilityIdentifier(accessibilityIdentifier)
    }

    private struct Style: ButtonStyle {
        let state: MEGAButtonState

        func makeBody(configuration: Configuration) -> some View {
            label(configuration)
                .font(.callout.bold())
                .frame(maxWidth: .infinity, minHeight: 24)
                .padding(TokenSpacing._4)
                .frame(minHeight: 48)
                .background(state.isEnabled ? TokenColors.Button.brand.swiftUI : TokenColors.Button.disabled.swiftUI)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .cornerRadius(TokenRadius.medium)
                .opacity(configuration.isPressed && state.isEnabled ? 0.8 : 1)
        }

        @ViewBuilder
        private func label(_ configuration: Configuration) -> some View {
            if state == .load {
                ProgressView()
                    .tint(TokenColors.Text.onColor.swiftUI)
            } else {
                configuration.label
            }
        }
    }
}

#Preview {
    VStack(spacing: TokenSpacing._4) {
        BrandButton(title: "Get Pro I") {}
        BrandButton(title: "Get Pro I", state: .disabled) {}
        BrandButton(title: "Get Pro I", state: .load) {}
    }
    .padding()
}
