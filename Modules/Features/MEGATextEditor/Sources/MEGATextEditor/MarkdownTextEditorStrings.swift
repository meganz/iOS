import MEGAL10n
import MEGAMarkdown
import MEGAMarkdownEditor

extension MarkdownEditorStrings {
    /// The editor strings from MEGAL10n. Computed, so a language change shows at once.
    public static var mega: MarkdownEditorStrings {
        typealias Texts = Strings.Localizable.MarkdownEditor
        return MarkdownEditorStrings(
            bold: Texts.Toolbar.bold,
            italic: Texts.Toolbar.italic,
            underline: Texts.Toolbar.underline,
            strikethrough: Texts.Toolbar.strikethrough,
            code: Texts.Toolbar.code,
            link: Texts.Toolbar.link,
            textStyle: Texts.Toolbar.textStyle,
            body: Texts.TextStyle.body,
            heading1: Texts.TextStyle.heading1,
            heading2: Texts.TextStyle.heading2,
            heading3: Texts.TextStyle.heading3,
            heading4: Texts.TextStyle.heading4,
            heading5: Texts.TextStyle.heading5,
            heading6: Texts.TextStyle.heading6,
            bulletList: Texts.Toolbar.bulletedList,
            numberedList: Texts.Toolbar.numberedList,
            taskList: Texts.Toolbar.taskList,
            quote: Texts.Toolbar.quote,
            indent: Texts.KeyCommand.indent,
            outdent: Texts.KeyCommand.outdent,
            linkDialogTitle: Texts.LinkDialog.title,
            linkURLLabel: Texts.LinkDialog.linkLabel,
            linkTextLabel: Texts.LinkDialog.textLabel,
            linkSave: Strings.Localizable.save,
            linkRemove: Strings.Localizable.remove,
            linkCancel: Strings.Localizable.cancel,
            fileTooLargeNotice: Texts.Notice.fileTooLargeForRichText,
            blockTooLongForRichNotice: Texts.Notice.sectionTooLongForRichText,
            lineTooLongNotice: Texts.Notice.lineTooLong,
            // The app never shows it. A file over 100 MB stops at the too-large alert before it opens.
            fileTooLargeToEditNotice: MarkdownEditorStrings.english.fileTooLargeToEditNotice,
            sourceEditor: Texts.Accessibility.sourceEditor,
            continueAtEnd: Texts.Accessibility.continueAtEnd
        )
    }
}

extension MarkdownPreviewStrings {
    /// The preview strings of the app. The app never shows the English `tooLarge` text.
    /// It stops a file over the preview size limit before the preview opens.
    public static var mega: MarkdownPreviewStrings {
        MarkdownPreviewStrings(
            tooLarge: MarkdownPreviewStrings.english.tooLarge,
            shownAsPlainText: Strings.Localizable.MarkdownEditor.Preview.sectionShownAsPlainText
        )
    }
}
