import MEGAAnalyticsiOS
import MEGAL10n
import MEGAMarkdownEditor

/// The editor modes the user can pick, in menu order.
public enum MarkdownTextEditorMode: CaseIterable, Equatable, Sendable {
    case plainText
    case richText

    public var title: String {
        switch self {
        case .plainText: Strings.Localizable.MarkdownEditor.Mode.plainText
        case .richText: Strings.Localizable.MarkdownEditor.Mode.richText
        }
    }

    /// The analytics event sent when the user picks this mode in the mode menu.
    public var menuItemEvent: any EventIdentifier {
        switch self {
        case .plainText: TextEditorPlainTextModeMenuItemEvent()
        case .richText: TextEditorRichTextModeMenuItemEvent()
        }
    }

    init(editorMode: MarkdownEditorMode) {
        switch editorMode {
        case .source: self = .plainText
        case .rich: self = .richText
        }
    }

    var editorMode: MarkdownEditorMode {
        switch self {
        case .plainText: .source
        case .richText: .rich
        }
    }
}
