import SwiftUI
import UIKit

struct PopoverPresentingToolbarAnchorView: UIViewRepresentable {
    let onReady: @MainActor (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        // Deferred so the caller never runs inside SwiftUI's view update.
        Task { @MainActor in onReady(view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
