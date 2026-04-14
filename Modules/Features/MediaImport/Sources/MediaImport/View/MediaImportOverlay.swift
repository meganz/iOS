import SwiftUI

@MainActor
public final class MediaImportOverlay {
    private var window: UIWindow?

    public init(viewModel: MediaImportProgressViewModel, presenter: UIViewController?) {
        let scene = presenter?.view.window?.windowScene
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }

        let window: UIWindow
        if let scene {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow()
        }

        window.windowLevel = .alert
        window.backgroundColor = .clear

        let hostingController = UIHostingController(rootView: MediaImportProgressView(viewModel: viewModel))
        hostingController.view.backgroundColor = .clear
        window.rootViewController = hostingController

        self.window = window
    }

    public func show() {
        guard window?.isHidden == true else { return }
        window?.isHidden = false
    }

    public func dismiss() {
        guard window != nil else { return }
        window?.isHidden = true
        window = nil
    }
}
