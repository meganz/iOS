import MEGAAssets
import MEGADesignToken
import MEGAMarkdown
import MEGAMarkdownEditor
import SwiftUI

/// Shows the content of a Markdown file. The host owns the navigation bar and the toolbar.
public struct MarkdownTextEditorContentView: View {
    @Bindable private var state: MarkdownTextEditorContentState
    private let onReadingPositionChange: ((MarkdownReadingPosition) -> Void)?

    /// - Parameters:
    ///   - onReadingPositionChange: Called when the top line or the read progress of the preview changes.
    public init(
        state: MarkdownTextEditorContentState,
        onReadingPositionChange: ((MarkdownReadingPosition) -> Void)? = nil
    ) {
        self.state = state
        self.onReadingPositionChange = onReadingPositionChange
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TokenColors.Background.page.swiftUI)
            .markdownPreviewStrings(.mega)
            .markdownEditorStrings(.mega)
    }

    @ViewBuilder
    private var content: some View {
        switch state.screen {
        case .loading:
            loading
        case .preview:
            MarkdownPreview(
                state.text,
                restoreLine: state.restoreLine,
                onReadingPositionChange: onReadingPositionChange
            )
        case .editor:
            MarkdownEditor(markdown: $state.text, mode: $state.mode, flusher: state.flusher)
        }
    }

    /// Matches the legacy text editor: the file icon above a green progress bar.
    private var loading: some View {
        VStack(spacing: 20) {
            MEGAAssets.Image.image(forFileName: state.fileName)
                .resizable()
                .frame(width: 80, height: 80)
            if let progress = state.loadingProgress {
                ProgressView(value: progress)
                    .tint(TokenColors.Support.success.swiftUI)
                    .frame(width: 150)
            } else {
                ProgressView()
            }
        }
    }
}
