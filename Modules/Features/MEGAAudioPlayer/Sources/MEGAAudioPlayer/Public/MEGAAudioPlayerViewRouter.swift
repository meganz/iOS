import SwiftUI
import UIKit

/// Public entry point for presenting the revamped audio player full-screen view.
///
/// Host app usage:
/// ```swift
/// let router = MEGAAudioPlayerViewRouter(
///     presenter: self,
///     actionsHandler: handler,
///     navigationFactory: { MEGAAudioPlayerNavigationController(rootViewController: $0) }
/// )
/// router.start(source: .cloudNode(node: node, queue: queue))     // start new playback
/// router.showCurrent()                                            // expand mini → full
/// ```
@MainActor
public final class MEGAAudioPlayerViewRouter {
    /// Invoked when the user taps the three-dot button. The host app
    /// builds and presents the appropriate action sheet from `hostVC`:
    /// - `.cloudNode` / `.folderLink` / `.chatMessage` / `.searchResult` →
    ///   legacy `NodeActionViewController` with the generic delegate.
    /// - `.fileLink` → `NodeActionViewController` with
    ///   `FileLinkActionViewControllerDelegate`.
    /// - `.offlineFiles` → never fires (the player hides the three-dot button
    ///   for offline playback, matching legacy behaviour).
    public typealias ActionsHandler = @MainActor (_ hostVC: UIViewController, _ source: PlaybackSource) -> Void

    /// Wraps the SwiftUI hosting controller in a `UINavigationController` of the
    /// host app's choosing.
    public typealias NavigationFactory = @MainActor (_ rootViewController: UIViewController) -> UINavigationController

    private weak var presenter: UIViewController?
    private let service: any AudioPlaybackServiceProtocol
    private let actionsHandler: ActionsHandler?
    private let navigationFactory: NavigationFactory

    /// Public entry point. Constructs the router with the shared
    /// `AudioPlaybackService` (singleton). Callers from outside the module use
    /// only this initialiser.
    public convenience init(
        presenter: UIViewController?,
        actionsHandler: ActionsHandler? = nil,
        navigationFactory: @escaping NavigationFactory
    ) {
        self.init(
            presenter: presenter,
            service: AudioPlaybackService.shared,
            actionsHandler: actionsHandler,
            navigationFactory: navigationFactory
        )
    }

    /// Internal designated initialiser. The `service` parameter is `internal`
    /// because `AudioPlaybackServiceProtocol` (and its concrete type) are
    /// internal to the module — used by tests/previews to inject a mock.
    init(
        presenter: UIViewController?,
        service: any AudioPlaybackServiceProtocol,
        actionsHandler: ActionsHandler? = nil,
        navigationFactory: @escaping NavigationFactory
    ) {
        self.presenter = presenter
        self.service = service
        self.actionsHandler = actionsHandler
        self.navigationFactory = navigationFactory
    }

    /// Start (or replace) playback with the given source and present the
    /// full-screen player. Use this from any "tap audio file → play" entry
    /// point in the host app.
    public func start(source: PlaybackSource) {
        service.play(source: source)
        present()
    }

    /// Present the full-screen player for whatever the service is currently
    /// playing — typical caller is the mini player when the user taps it to
    /// expand. Does NOT change what is playing.
    public func showCurrent() {
        present()
    }

    private func present() {
        // `presentedViewController == nil` guards against double-presenting —
        // e.g. a fast double-tap on the mini player pill firing `showCurrent()`
        // twice before the first presentation lands.
        guard let presenter, presenter.presentedViewController == nil else { return }
        let host = build()
        host.modalPresentationStyle = .fullScreen
        presenter.present(host, animated: true)
    }

    private func build() -> UIViewController {
        let vm = AudioPlayerViewModel(service: service)
        let host = UIHostingController(rootView: AudioPlayerView(vm: vm))

        // Inject the UIKit dismiss into the VM so the chevron-down button can
        // actually close this modal. SwiftUI's `@Environment(\.dismiss)` doesn't
        // bridge to UIKit's `present(_:animated:)`, so the VM-driven callback is
        // the reliable path.
        vm.onDismiss = { [weak host] in
            host?.dismiss(animated: true)
        }

        let actionsHandler = self.actionsHandler
        vm.onMoreTap = { [weak host] source in
            guard let host, let actionsHandler else { return }
            actionsHandler(host, source)
        }

        // Wrap in a UIKit UINavigationController so SwiftUI's `ToolbarItem(placement:)`
        // declared inside the View propagates onto an actual UINavigationBar.
        // iOS 26 then applies its default Liquid Glass treatment to the bar buttons
        // automatically. We configure the bar's appearance to fully transparent so the
        // gradient background underneath bleeds through — relying on SwiftUI's
        // `.toolbarBackground(.hidden, ...)` is flaky under modal + dark override and
        // can leave a solid dark bar on top of the content.
        let nav = navigationFactory(host)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        host.extendedLayoutIncludesOpaqueBars = true

        // Force dark mode for the entire trait collection so MEGADesignToken
        // colours (resolved via UITraitCollection) match the design's dark-only
        // palette regardless of the system / presenter theme.
        nav.overrideUserInterfaceStyle = .dark
        return nav
    }
}
