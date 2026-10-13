import SwiftUI

/// Every user-visible string of `MarkdownEditor`.
/// The init has no defaults on purpose: a consumer must pass every string, so a new string
/// breaks its build instead of silently showing English. `.english` is the environment default.
public struct MarkdownEditorStrings: Equatable, Sendable {
    // MARK: - Toolbar (accessibility labels)

    /// Toolbar button that makes text bold.
    public var bold: String
    /// Toolbar button that makes text italic.
    public var italic: String
    /// Toolbar button that underlines text.
    public var underline: String
    /// Toolbar button that strikes text through.
    public var strikethrough: String
    /// Toolbar button that formats text as inline code.
    public var code: String
    /// Toolbar button that adds, edits or removes a link.
    public var link: String
    /// Toolbar chip that opens the text style menu.
    public var textStyle: String
    /// Text style name of a paragraph, in the chip and the menu.
    public var body: String
    /// Text style names of heading levels 1 to 6. The menu offers levels 1 to 3.
    public var heading1: String
    public var heading2: String
    public var heading3: String
    public var heading4: String
    public var heading5: String
    public var heading6: String
    /// Toolbar button that turns the block into a bullet list item.
    public var bulletList: String
    /// Toolbar button that turns the block into a numbered list item.
    public var numberedList: String
    /// Toolbar button that turns the block into a task list item.
    public var taskList: String
    /// Toolbar button that turns the block into a quote.
    public var quote: String
    /// Tab key command that indents a list item. Shown in the iPad shortcut list.
    public var indent: String
    /// ⇧Tab key command that outdents a list item. Shown in the iPad shortcut list.
    public var outdent: String

    // MARK: - Link dialog

    /// Title of the link dialog.
    public var linkDialogTitle: String
    /// Label above the link URL field.
    public var linkURLLabel: String
    /// Label above the link text field.
    public var linkTextLabel: String
    /// Button that saves the link.
    public var linkSave: String
    /// Button that removes the link.
    public var linkRemove: String
    /// Button that closes the link dialog without changes.
    public var linkCancel: String

    // MARK: - Notices

    /// Shown when the file is too large for rich mode (over 500,000 characters) and opens as source.
    public var fileTooLargeNotice: String
    /// Shown when one block of the file is too long for rich mode (over 100,000 characters) and the file opens as source.
    public var blockTooLongForRichNotice: String
    /// Shown instead of the source when a line is too long to edit (over 100,000 characters).
    public var lineTooLongNotice: String
    /// Shown instead of the source when the file is over 100 MB.
    public var fileTooLargeToEditNotice: String
    /// VoiceOver name of the button that closes a notice.
    public var closeNotice: String

    // MARK: - Accessibility

    /// VoiceOver name of the plain text editor in source mode.
    public var sourceEditor: String
    /// VoiceOver name of the empty area below the last block. Tapping it continues typing at the end.
    public var continueAtEnd: String

    public init(
        bold: String,
        italic: String,
        underline: String,
        strikethrough: String,
        code: String,
        link: String,
        textStyle: String,
        body: String,
        heading1: String,
        heading2: String,
        heading3: String,
        heading4: String,
        heading5: String,
        heading6: String,
        bulletList: String,
        numberedList: String,
        taskList: String,
        quote: String,
        indent: String,
        outdent: String,
        linkDialogTitle: String,
        linkURLLabel: String,
        linkTextLabel: String,
        linkSave: String,
        linkRemove: String,
        linkCancel: String,
        fileTooLargeNotice: String,
        blockTooLongForRichNotice: String,
        lineTooLongNotice: String,
        fileTooLargeToEditNotice: String,
        closeNotice: String,
        sourceEditor: String,
        continueAtEnd: String
    ) {
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.code = code
        self.link = link
        self.textStyle = textStyle
        self.body = body
        self.heading1 = heading1
        self.heading2 = heading2
        self.heading3 = heading3
        self.heading4 = heading4
        self.heading5 = heading5
        self.heading6 = heading6
        self.bulletList = bulletList
        self.numberedList = numberedList
        self.taskList = taskList
        self.quote = quote
        self.indent = indent
        self.outdent = outdent
        self.linkDialogTitle = linkDialogTitle
        self.linkURLLabel = linkURLLabel
        self.linkTextLabel = linkTextLabel
        self.linkSave = linkSave
        self.linkRemove = linkRemove
        self.linkCancel = linkCancel
        self.fileTooLargeNotice = fileTooLargeNotice
        self.blockTooLongForRichNotice = blockTooLongForRichNotice
        self.lineTooLongNotice = lineTooLongNotice
        self.fileTooLargeToEditNotice = fileTooLargeToEditNotice
        self.closeNotice = closeNotice
        self.sourceEditor = sourceEditor
        self.continueAtEnd = continueAtEnd
    }

    /// English strings. Used when the consumer sets nothing, and by previews and tests.
    public static let english = MarkdownEditorStrings(
        bold: "Bold",
        italic: "Italic",
        underline: "Underline",
        strikethrough: "Strikethrough",
        code: "Code",
        link: "Link",
        textStyle: "Text style",
        body: "Body",
        heading1: "Heading 1",
        heading2: "Heading 2",
        heading3: "Heading 3",
        heading4: "Heading 4",
        heading5: "Heading 5",
        heading6: "Heading 6",
        bulletList: "Bulleted list",
        numberedList: "Numbered list",
        taskList: "Task list",
        quote: "Quote",
        indent: "Indent",
        outdent: "Outdent",
        linkDialogTitle: "Add link",
        linkURLLabel: "Link",
        linkTextLabel: "Text",
        linkSave: "Save",
        linkRemove: "Remove",
        linkCancel: "Cancel",
        fileTooLargeNotice: "This file is too large for rich text. Showing the Markdown source.",
        blockTooLongForRichNotice: "This file has a block that is too long for rich text. Showing the Markdown source.",
        lineTooLongNotice: "This file has a very long line, so editing may be slow.",
        fileTooLargeToEditNotice: "This file is too large to edit.",
        closeNotice: "Close",
        sourceEditor: "Markdown source",
        continueAtEnd: "Continue at the end"
    )
}

// MARK: - Text style names

extension MarkdownEditorStrings {
    /// "Body" for nil, else "Heading N".
    func styleName(forHeading level: Int?) -> String {
        switch level {
        case nil: body
        case 1: heading1
        case 2: heading2
        case 3: heading3
        case 4: heading4
        case 5: heading5
        default: heading6
        }
    }
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var markdownEditorStrings = MarkdownEditorStrings.english
}

extension View {
    /// Sets the strings for every `MarkdownEditor` below this view.
    /// Build them when the view is drawn (for example a computed `static var`), not once in a `static let`.
    public func markdownEditorStrings(_ strings: MarkdownEditorStrings) -> some View {
        environment(\.markdownEditorStrings, strings)
    }
}
