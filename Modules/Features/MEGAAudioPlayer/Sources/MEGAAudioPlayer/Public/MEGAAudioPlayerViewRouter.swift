import MEGADomain
import SwiftUI
import UIKit

/// Public entry point for presenting the revamped audio player full-screen view.
///
/// Host app usage:
/// ```swift
/// let router = MEGAAudioPlayerViewRouter(
///     presenter: self,
///     actionsHandler: handler
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

    private weak var presenter: UIViewController?
    private let service: any AudioPlaybackServiceProtocol
    private let actionsHandler: ActionsHandler?
    private let accountUseCase: any AccountUseCaseProtocol

    /// Public entry point. Constructs the router with the shared
    /// `AudioPlaybackService` (singleton). Callers from outside the module use
    /// only this initialiser.
    public convenience init(
        presenter: UIViewController?,
        actionsHandler: ActionsHandler? = nil
    ) {
        self.init(
            presenter: presenter,
            service: AudioPlaybackService.shared,
            actionsHandler: actionsHandler
        )
    }

    /// Internal designated initialiser. The `service` parameter is `internal`
    /// because `AudioPlaybackServiceProtocol` (and its concrete type) are
    /// internal to the module — used by tests/previews to inject a mock.
    init(
        presenter: UIViewController?,
        service: any AudioPlaybackServiceProtocol,
        actionsHandler: ActionsHandler? = nil,
        accountUseCase: any AccountUseCaseProtocol = DependencyInjection.accountUseCase
    ) {
        self.presenter = presenter
        self.service = service
        self.actionsHandler = actionsHandler
        self.accountUseCase = accountUseCase
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
        host.modalPresentationStyle = .overFullScreen
        presenter.present(host, animated: true)
    }

    private func build() -> UIViewController {
        let vm = AudioPlayerViewModel(service: service)
        let host = AudioPlayerHostingController(rootView: AudioPlayerView(vm: vm))
        host.isPlaylistVisible = { [weak vm] in vm?.isPlaylistVisible == true }
        host.playlistListTopY = { [weak vm] in vm?.playlistListTopY ?? 0 }

        let service = service
        let accountUseCase = accountUseCase
        let stopPlaybackIfLoggedOut = {
            if !accountUseCase.isLoggedIn() {
                service.stop()
            }
        }

        vm.onDismiss = { [weak host] in
            host?.dismiss(animated: true)
            stopPlaybackIfLoggedOut()
        }

        host.onDismiss = stopPlaybackIfLoggedOut

        let actionsHandler = self.actionsHandler
        vm.onMoreTap = { [weak host] source in
            guard let host, let actionsHandler else { return }
            actionsHandler(host, source)
        }

        host.view.backgroundColor = .clear
        host.overrideUserInterfaceStyle = .dark
        return host
    }
}
