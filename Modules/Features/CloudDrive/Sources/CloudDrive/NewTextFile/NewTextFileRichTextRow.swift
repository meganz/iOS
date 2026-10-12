import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// The Rich text formatting row of the New text file dialog.
struct NewTextFileRichTextRow: View {
    @Binding var isChecked: Bool

    var body: some View {
        // The row is one button, so a tap on the label also toggles the box.
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: TokenSpacing._3) {
                MEGAChecklist(isChecked: .constant(isChecked))
                    .allowsHitTesting(false)
                Text(Strings.Localizable.MarkdownEditor.NewFile.richTextFormatting)
                    .font(.callout)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Localizable.MarkdownEditor.NewFile.richTextFormatting)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isChecked ? "1" : "0")
    }
}
