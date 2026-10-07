import SafariServices
import SwiftUI

/// Shows a web page inside the app. The close button calls `onClose`.
/// A pushed page does not go back by itself when the user taps close, so the owner pops it.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onClose: () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private let onClose: () -> Void

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onClose()
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
