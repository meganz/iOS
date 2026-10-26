import MEGAMarkdownEditor
import Observation

/// What the Markdown file content shows. The screen that owns it writes it. The content view reads it.
@Observable @MainActor
public final class MarkdownTextEditorContentState {
    public enum Screen: Equatable, Sendable {
        /// The file is downloading. `loadingProgress` tells how far.
        case loading
        case preview
        case editor
    }

    public var screen: Screen = .loading
    /// The loading screen shows the file type icon of this name.
    public var fileName = ""
    /// From 0 to 1. nil while the progress is not known.
    public var loadingProgress: Double?
    /// The Markdown text. The editor writes the user's edits here.
    public var text = ""
    /// 0-based source line the preview opens at. nil opens at the top.
    public var restoreLine: Int?
    var mode: MarkdownEditorMode = .rich
    @ObservationIgnored let flusher = MarkdownEditorFlusher()

    public init() {}

    /// The mode the user picked in the editor.
    public var textEditorMode: MarkdownTextEditorMode {
        get { MarkdownTextEditorMode(editorMode: mode) }
        set { mode = newValue.editorMode }
    }

    /// Edit always starts in rich mode. The editor falls back to the source by itself.
    public func showEditor() {
        mode = .rich
        screen = .editor
    }

    /// Writes the edits that wait for the idle save into `text`. A host calls it before a save.
    public func flushEditor() {
        flusher.flush()
    }
}
