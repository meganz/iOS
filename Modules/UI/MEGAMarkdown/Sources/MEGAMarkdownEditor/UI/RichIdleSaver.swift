import SwiftUI

/// Saves `delay` after the last change (1 s by default). Each change restarts the wait, so typing never saves.
/// A small view of its own, so only it reads `editVersion` and a key redraws nothing else.
struct RichIdleSaver: View {
    let model: RichEditorModel
    var delay: Duration = .seconds(1)

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .task(id: model.editVersion) {
                // A cancelled sleep means a new change came in: that change starts its own wait.
                do {
                    try await Task.sleep(for: delay)
                    // Marked text is not final. A save would write it, and the end of the typing burst would
                    // make an undo step of it.
                    while model.hasMarkedText() {
                        try await Task.sleep(for: delay)
                    }
                } catch {
                    return
                }
                await model.idle()
            }
    }
}

extension EnvironmentValues {
    /// The wait of `RichIdleSaver` in the editor. Tests set a short one.
    @Entry var richIdleDelay: Duration = .seconds(1)
}
