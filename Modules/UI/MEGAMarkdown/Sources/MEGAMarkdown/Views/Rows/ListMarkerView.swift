import SwiftUI

/// The bullet, number or checkbox in front of a list item.
package struct ListMarkerView: View {
    let marker: MarkdownListMarker
    /// The checkbox's VoiceOver label: the item's text. Other markers ignore it.
    let label: String
    /// Nil: the checkbox only shows its state. Otherwise a tap on the box calls it.
    let onToggle: (() -> Void)?

    @Environment(\.markdownTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var checkboxBaselineOffset = MarkdownBlockView.checkboxBaselineOffset

    package init(marker: MarkdownListMarker, label: String, onToggle: (() -> Void)? = nil) {
        self.marker = marker
        self.label = label
        self.onToggle = onToggle
    }

    package var body: some View {
        switch marker {
        case .checkbox(let isChecked):
            // The guide closure is Sendable, so it takes a copy of the main-actor value.
            let offset = checkboxBaselineOffset
            CheckboxMarker(isChecked: isChecked, label: label, onToggle: onToggle)
                // The box has no text baseline. Center it on the first line of body text.
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + offset }
        case .number(let number):
            Text(verbatim: "\(number).")
                .font(theme.bodyFont.monospacedDigit())
                .foregroundStyle(theme.bodyColor)
                // A long number keeps its full width. The item text gets the rest.
                .fixedSize()
        case .bullet:
            Text(verbatim: "•")
                .font(theme.bodyFont)
                .foregroundStyle(theme.bodyColor)
        }
    }
}

/// VoiceOver reads the box as a system Toggle, so the state is read in the user's language.
/// Its label is the item text, so VoiceOver says which task it is.
private struct CheckboxMarker: View {
    let isChecked: Bool
    let label: String
    let onToggle: (() -> Void)?

    var body: some View {
        if let onToggle {
            Button(action: onToggle) {
                MarkdownCheckbox(isChecked: isChecked)
            }
            // The plain style dims the box while pressed and fades it back. The checkbox shows its new state at once.
            .buttonStyle(NoPressEffectButtonStyle())
            .accessibilityRepresentation {
                Toggle(isOn: Binding(get: { isChecked }, set: { _ in onToggle() })) {
                    Text(label)
                }
                .labelsHidden()
                .fixedSize()
            }
        } else {
            MarkdownCheckbox(isChecked: isChecked)
                .accessibilityRepresentation {
                    Toggle(isOn: .constant(isChecked)) {
                        Text(label)
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(true)
                }
        }
    }
}

/// Shows the label as it is: no dimming and no animation while pressed.
private struct NoPressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
