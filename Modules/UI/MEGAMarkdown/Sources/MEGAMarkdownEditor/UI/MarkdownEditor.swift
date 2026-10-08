import MEGADesignToken
import MEGAFoundation
import SwiftUI

public enum MarkdownEditorMode: Equatable, Sendable {
    /// WYSIWYG block editor. No Markdown syntax on screen.
    case rich
    /// Plain text editor on the raw Markdown.
    case source
}

/// Markdown editor with a rich mode and a source mode. Edits reach `markdown` after 1 s idle, on a mode switch,
/// on disappear and on app background. The binding must store the value at once (for example `@State`).
/// It must return exactly the value written. Any other new value is an outside change.
/// An outside change replaces the unsaved edits. In rich mode it also clears the undo history.
public struct MarkdownEditor: View {
    /// In UTF-16 units. A larger file opens in source mode with a notice.
    public static let richModeCharacterLimit = RichTextLimit.maxLength

    @Binding private var markdown: String
    @Binding private var mode: MarkdownEditorMode
    /// Resolves relative links and images of blocks shown read-only in rich mode.
    private let baseURL: URL?
    /// Why rich mode shows the source instead. Decided on appear, on a mode change, and on an outside change in rich mode.
    /// So cutting the file while typing in the source never swaps editors and drops the keyboard.
    @State private var richRefusal: RichModeRefusal?
    /// The text a load refused for a too-long block. Only a load finds this, so appear skips it for the same text.
    @State private var blockTooLongText: String?
    /// nil while rich mode loads, and in source mode.
    @State private var richAdapter: RichRowAdapter?
    /// Grows each time rich mode must load again. The load task restarts on each change.
    @State private var loadRequest = 0
    /// The source text view owns the text while the user types. This writes it back.
    @State private var sourceSync = SourceTextSync()
    /// nil while the source text is checked off the main thread. Grows when it must be checked again.
    @State private var sourceLimit: SourceTextLimit?
    @State private var sourceCheckRequest = 0
    @Environment(\.markdownEditorStrings) private var strings

    /// - Parameters:
    ///   - markdown: The Markdown text. Rich-mode edits are written back only when the export changed.
    ///   - mode: Rich or source mode. Files over `richModeCharacterLimit` always show the source.
    ///   - baseURL: Resolves relative links and images.
    public init(markdown: Binding<String>, mode: Binding<MarkdownEditorMode>, baseURL: URL? = nil) {
        _markdown = markdown
        _mode = mode
        self.baseURL = baseURL
    }

    private var richModel: RichEditorModel? {
        richAdapter?.model
    }

    private var showsSource: Bool {
        mode != .rich || richRefusal != nil
    }

    public var body: some View {
        // The parent can point the binding at other storage without a new view, so take it on every render.
        setFlushTarget()
        return content
    }

    private var content: some View {
        Group {
            if showsSource {
                sourceEditor
            } else {
                if let richAdapter {
                    RichEditorView(adapter: richAdapter, baseURL: baseURL)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            // Back from a pushed screen: the loaded model is still current, so keep its undo and caret.
            if let richModel, richModel.holds(markdown) { return }
            // The same text is still refused. A new load would swap the source view for a spinner and back.
            if richRefusal == .blockTooLong, let blockTooLongText, markdown.hasSameBytes(as: blockTooLongText) { return }
            if mode == .rich {
                requestRichMode()
            }
        }
        .onChange(of: mode) { _, newMode in
            MEGALog.log(level: .info, message: "[MarkdownEditor] Mode switch. rich=\(newMode == .rich) utf8Bytes=\(markdown.utf8.count)")
            if newMode == .rich {
                // The rich load must see the last keys typed in the source.
                sourceSync.flushForModeSwitch()
                requestRichMode()
            } else {
                richModel?.exportChanges()
                dropRichModel()
                requestSourceCheck()
            }
        }
        .onChange(of: MarkdownBytes(text: markdown)) { _, new in
            let newValue = new.text
            let isModeSwitchWrite = sourceSync.isModeSwitchWrite(newValue)
            if showsSource {
                // Our own write-back equals `lastSynced`. Anything else is an outside change: check it again.
                if !newValue.hasSameBytes(as: sourceSync.lastSynced) {
                    sourceSync.takeOutsideText(newValue)
                    requestSourceCheck()
                }
                return
            }
            // The flush for the mode switch already started the rich load.
            if isModeSwitchWrite { return }
            // Our own export comes back through the binding. Only an outside change reloads.
            if let richModel, richModel.holds(newValue) { return }
            requestRichMode()
        }
        .task(id: loadRequest) {
            await loadRichMode()
        }
        .task(id: sourceCheckRequest) {
            await checkSourceText()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // The app may be killed in the background. scenePhase does not always update in a UIKit host.
            flushAll()
        }
        .onDisappear {
            flushAll()
        }
    }

    private func setFlushTarget() {
        sourceSync.onFlush = { [$markdown] text in
            $markdown.wrappedValue = text
        }
        // The rich model writes to the binding of the latest render, not the binding it was loaded with.
        richModel?.onExport = { [$markdown] text in
            $markdown.wrappedValue = text
        }
    }

    /// Drops the rich model. A save that is still running must not write to the binding any more.
    private func dropRichModel() {
        richModel?.onExport = nil
        richAdapter = nil
    }

    private func flushAll() {
        sourceSync.flush()
        richModel?.exportChanges()
    }

    private var sourceEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            if mode == .rich, let richRefusal {
                Text(richRefusal.notice(in: strings))
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .padding(TokenSpacing._3)
                    .accessibilityIdentifier("editor.richRefusalNotice")
            }
            switch sourceLimit {
            case .editable:
                // Plain text mode shows no toolbar, because it edits raw Markdown. Figma `4938:32467`: monospace footnote,
                // text 16 from the sides. The text view already pads the line and insets 8 at the top, so add only the rest.
                SourceTextView(markdown: markdown, sync: sourceSync)
                    .equatable()
                    .padding(.horizontal, TokenSpacing._5 - NSTextContainer().lineFragmentPadding)
            case .lineTooLong:
                sourceNotice(strings.lineTooLongNotice)
            case .fileTooLarge:
                sourceNotice(strings.fileTooLargeToEditNotice)
            case nil:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(TokenColors.Background.page.swiftUI)
    }

    private func sourceNotice(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .multilineTextAlignment(.center)
            .padding(TokenSpacing._5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("editor.sourceNotice")
    }

    /// Hides the source view until the text is checked again.
    private func requestSourceCheck() {
        sourceLimit = nil
        sourceCheckRequest += 1
    }

    /// The scan reads the whole text (tens of ms at 100 MB), so it runs off the main thread.
    private func checkSourceText() async {
        // The task starts again on each appear. A limit that is already known is still valid:
        // every text change that matters sets `sourceLimit` to nil first.
        guard showsSource, sourceLimit == nil else { return }
        let text = markdown
        let limit = await Self.sourceLimit(of: text)
        guard !Task.isCancelled, text.hasSameBytes(as: markdown) else { return }
        if limit != .editable {
            MEGALog.log(level: .info, message: "[MarkdownEditor] Plain text shows a notice, no text view. limit=\(limit) utf8Bytes=\(text.utf8.count)")
        }
        sourceLimit = limit
    }

    @concurrent
    private nonisolated static func sourceLimit(of text: String) async -> SourceTextLimit {
        SourceTextLimit.check(text)
    }

    /// Drops the current rich model and decides again whether rich mode can show the text.
    /// A refused text shows the source, so the source is checked too. Else a new load starts.
    private func requestRichMode() {
        let wasShowingSource = showsSource
        dropRichModel()
        richRefusal = RichModeRefusal.check(markdown)
        guard let richRefusal else {
            loadRequest += 1
            return
        }
        refuseRichMode(richRefusal, wasShowingSource: wasShowingSource)
    }

    private func refuseRichMode(_ refusal: RichModeRefusal, wasShowingSource: Bool) {
        richRefusal = refusal
        MEGALog.log(level: .info, message: "[MarkdownEditor] Rich mode refused, showing plain text. reason=\(refusal) utf8Bytes=\(markdown.utf8.count)")
        if !wasShowingSource || sourceLimit == nil { requestSourceCheck() }
    }

    /// Loads off the main thread. A result for text or a mode that changed meanwhile is dropped.
    private func loadRichMode() async {
        // `.task` runs again each time the view appears. A loaded model stays, with its undo and caret.
        guard loadRequest > 0, mode == .rich, richRefusal == nil, richAdapter == nil else { return }
        let source = markdown
        let outcome = await RichEditorLoad.load(source)
        guard !Task.isCancelled, mode == .rich, richRefusal == nil, source.hasSameBytes(as: markdown) else {
            MEGALog.log(level: .debug, message: "[MarkdownEditor] Rich load result dropped, the text or mode changed. utf8Bytes=\(source.utf8.count)")
            return
        }
        switch outcome {
        case .blockTooLong:
            blockTooLongText = source
            refuseRichMode(.blockTooLong, wasShowingSource: false)
        case .loaded(let load):
            let model = RichEditorModel(editor: load.editor)
            model.onExport = { [$markdown] newMarkdown in
                $markdown.wrappedValue = newMarkdown
            }
            richAdapter = RichRowAdapter(model: model, load: load)
        }
    }
}

/// Why rich mode shows the source instead.
enum RichModeRefusal: Equatable, Sendable {
    /// Over `RichTextLimit.maxLength`.
    case fileTooLarge
    /// A block is over `RichEditorLoad.maxBlockLength`. Known only after the load.
    case blockTooLong

    /// The check before the load. O(1) for most texts, so it runs on the main thread.
    static func check(_ markdown: String) -> RichModeRefusal? {
        RichTextLimit.allowsRichMode(markdown) ? nil : .fileTooLarge
    }

    func notice(in strings: MarkdownEditorStrings) -> String {
        switch self {
        case .fileTooLarge: strings.fileTooLargeNotice
        case .blockTooLong: strings.blockTooLongForRichNotice
        }
    }
}

/// `markdown` for `onChange`. Its `==` compares bytes: `String ==` takes tens of ms on large non-ASCII text.
private struct MarkdownBytes: Equatable {
    let text: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text.hasSameBytes(as: rhs.text)
    }
}

private struct MarkdownEditorPreviewHost: View {
    @State private var markdown = """
    # Markdown editor

    Some **bold**, *italic* and `code` text with a [link](https://mega.io).

    - [ ] Task to do
    - [x] Done task
    """
    @State private var mode = MarkdownEditorMode.source

    var body: some View {
        MarkdownEditor(markdown: $markdown, mode: $mode)
    }
}

#Preview {
    MarkdownEditorPreviewHost()
}
