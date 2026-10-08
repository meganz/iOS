import MEGADesignToken
import SwiftUI

/// Floating formatting toolbar above the keyboard (Figma `toolbar/light`).
struct RichFormattingToolbar: View {
    let model: RichEditorModel
    @Environment(\.markdownEditorStrings) private var strings

    var body: some View {
        let toolbar = model.toolbar
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TokenSpacing._3) {
                headingChip(toolbar)
                ForEach(Self.buttons(model: model, strings: strings), id: \.id) { button in
                    iconButton(button)
                }
            }
        }
        // At large text sizes the chip grows, so the bar grows with it (40 is the Figma minimum).
        .frame(minHeight: TokenSpacing._11)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(Capsule())
        .padding(TokenSpacing._2)
        .toolbarGlass(in: Capsule())
    }

    /// Shows the style of the caret's row. A tap opens the native heading menu.
    private func headingChip(_ toolbar: RichToolbarState) -> some View {
        // Without focus there is no target for the change, so every button is off.
        let enabled = model.isFocused && toolbar.canStyle
        let name = strings.styleName(forHeading: toolbar.headingLevel)
        let levels: [Int?] = [1, 2, 3, nil]
        return Menu {
            ForEach(levels, id: \.self) { level in
                Button {
                    model.apply(.setHeading(level))
                } label: {
                    if level == toolbar.headingLevel {
                        Label(strings.styleName(forHeading: level), systemImage: "checkmark")
                    } else {
                        Text(strings.styleName(forHeading: level))
                    }
                }
                .accessibilityIdentifier("toolbar.heading.menu.\(level.map(String.init) ?? "body")")
            }
        } label: {
            HStack(spacing: TokenSpacing._2) {
                Text(name)
                    .font(.callout)
                    .lineLimit(1)
                    .fixedSize()
                MarkdownEditorIcon.chevronDown.image
            }
            .foregroundStyle(enabled ? TokenColors.Text.primary.swiftUI : TokenColors.Text.disabled.swiftUI)
            .padding(.leading, TokenSpacing._4)
            .padding(.trailing, TokenSpacing._3)
            .padding(.vertical, TokenSpacing._2)
            .frame(minWidth: TokenSpacing._15, minHeight: TokenSpacing._11)
        }
        .disabled(!enabled)
        .accessibilityLabel(strings.textStyle)
        .accessibilityValue(name)
        .accessibilityIdentifier("toolbar.textStyle")
    }

    /// The icon buttons after the chip, in Figma order. A plain list, so tests can run each action.
    static func buttons(model: RichEditorModel, strings: MarkdownEditorStrings) -> [ToolbarButton] {
        let toolbar = model.toolbar
        func styleButton(_ style: RichSpanStyle, _ icon: MarkdownEditorIcon, _ id: String, _ label: String) -> ToolbarButton {
            let isActive = toolbar.activeStyles.contains(style)
            return ToolbarButton(id: id, icon: icon, label: label, isActive: isActive, isEnabled: model.isFocused && toolbar.canStyle) {
                model.toggleStyle(style)
            }
        }
        func blockButton(_ action: RichBlockAction, _ icon: MarkdownEditorIcon, _ id: String, _ label: String, _ isActive: Bool) -> ToolbarButton {
            ToolbarButton(id: id, icon: icon, label: label, isActive: isActive, isEnabled: model.isFocused) {
                model.apply(action)
            }
        }
        return [
            styleButton(.bold, .bold, "bold", strings.bold),
            styleButton(.italic, .italic, "italic", strings.italic),
            styleButton(.underline, .underline, "underline", strings.underline),
            styleButton(.strikethrough, .strikethrough, "strikethrough", strings.strikethrough),
            blockButton(.toggleTaskList, .checklist, "task", strings.taskList, toolbar.list == .task),
            blockButton(.toggleBulletList, .bulletList, "bullet", strings.bulletList, toolbar.list == .bullet),
            blockButton(.toggleOrderedList, .numberedList, "ordered", strings.numberedList, toolbar.list == .numbered),
            blockButton(.toggleQuote, .quote, "quote", strings.quote, toolbar.isQuote),
            styleButton(.code, .code, "code", strings.code),
            // Selected while the dialog is open, though the row lost focus to the dialog field.
            ToolbarButton(
                id: "link",
                icon: .link,
                label: strings.link,
                isActive: toolbar.isLinkOn || model.linkDialog != nil,
                isEnabled: model.isFocused && toolbar.canEditLink,
                action: model.beginLinkEditing
            )
        ]
    }

    private func iconButton(_ button: ToolbarButton) -> some View {
        Button(action: button.action) {
            button.icon.image
                .frame(width: TokenSpacing._11, height: TokenSpacing._11)
                .background(Circle().fill(button.isActive ? TokenColors.Background.surface3.swiftUI : Color.clear))
                .foregroundStyle(button.isEnabled ? TokenColors.Icon.primary.swiftUI : TokenColors.Icon.disabled.swiftUI)
        }
        .buttonStyle(.plain)
        .disabled(!button.isEnabled)
        .accessibilityLabel(button.label)
        .accessibilityIdentifier("toolbar.\(button.id)")
        .accessibilityAddTraits(button.isActive ? .isSelected : [])
    }
}

/// One toolbar icon button and what it does.
struct ToolbarButton {
    let id: String
    let icon: MarkdownEditorIcon
    let label: String
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void
}
