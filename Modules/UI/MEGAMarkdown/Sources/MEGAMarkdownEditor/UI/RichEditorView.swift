import MEGADesignToken
import SwiftUI

/// Rich mode: the rows, the formatting toolbar, the link alert and the idle save.
struct RichEditorView: View {
    let adapter: RichRowAdapter
    let baseURL: URL?
    @Environment(\.richIdleDelay) private var idleDelay

    var body: some View {
        let model = adapter.model
        RichEditorRowList(adapter: adapter, baseURL: baseURL)
            // Figma page color in both modes. Without it dark mode shows the system black.
            .background(TokenColors.Background.page.swiftUI.ignoresSafeArea())
            .background { RichIdleSaver(model: model, delay: idleDelay) }
            .safeAreaInset(edge: .bottom) {
                RichEditorControls(model: model)
            }
            .modifier(LinkAlert(model: model) {
                model.setFocused(true)
                adapter.focusSelection()
            })
    }
}

/// The toolbar at the bottom. A view of its own, so only it reads the toolbar state.
private struct RichEditorControls: View {
    let model: RichEditorModel

    var body: some View {
        // Always shown, so it tells the user this is an editor. It rides above the keyboard.
        RichFormattingToolbar(model: model)
            .padding(.horizontal, TokenSpacing._4)
            .padding(.bottom, TokenSpacing._3)
    }
}
