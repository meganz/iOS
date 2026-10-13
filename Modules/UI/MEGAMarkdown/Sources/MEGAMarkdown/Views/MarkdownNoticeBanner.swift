import MEGADesignToken
import SwiftUI

/// A yellow warning banner with a close button.
/// The editor shows it full width at the top. The preview shows it inline, with round corners.
package struct MarkdownNoticeBanner: View {
    let text: String
    let isInline: Bool
    let closeLabel: String
    /// nil hides the close button.
    let onClose: (() -> Void)?

    package init(text: String, isInline: Bool, closeLabel: String, onClose: (() -> Void)?) {
        self.text = text
        self.isInline = isInline
        self.closeLabel = closeLabel
        self.onClose = onClose
    }

    package var body: some View {
        HStack(spacing: TokenSpacing._5) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onClose {
                Button(action: onClose) {
                    Image("x", bundle: .module)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        // A 44 pt tap area. The negative padding keeps the 24 pt icon size in the layout.
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(-10)
                .accessibilityLabel(closeLabel)
            }
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        // A background shape, not a clip, so the tap area can reach past the padding.
        .background(TokenColors.Notifications.notificationWarning.swiftUI, in: RoundedRectangle(cornerRadius: isInline ? TokenRadius.medium : 0))
    }
}
