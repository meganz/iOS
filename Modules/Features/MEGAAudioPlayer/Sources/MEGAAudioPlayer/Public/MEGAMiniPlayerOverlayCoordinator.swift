import Combine
import SwiftUI
import UIKit

/// Coordinates the mini player's presence above the tab bar.
@MainActor
public final class MEGAMiniPlayerOverlayCoordinator {
    /// Height the host should reserve for the pill in its overlay container.
    public static let preferredHeight: CGFloat = 44

    /// Invoked when a playback session becomes active
    public var onAttach: ((UIViewController, CGFloat) -> Void)?

    /// Invoked when the playback session ends
    public var onDetach: ((UIViewController) -> Void)?

    /// Invoked when the user taps the pill to expand the full-screen player
    public var onExpand: (() -> Void)?

    private let service: any AudioPlaybackServiceProtocol
    private var cancellable: AnyCancellable?
    private var host: UIViewController?

    public convenience init() {
        self.init(service: AudioPlaybackService.shared)
    }

    /// Internal designated initialiser — used by tests to inject a mock
    init(service: any AudioPlaybackServiceProtocol) {
        self.service = service
    }

    /// Starts mirroring the playback session into attach/detach callbacks
    public func startObserving() {
        cancellable = service.statePublisher
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] hasActiveSession in
                hasActiveSession ? self?.attach() : self?.detach()
            }
    }

    private func attach() {
        guard host == nil else { return }
        let viewModel = MiniPlayerViewModel(service: service)
        viewModel.onExpand = { [weak self] in self?.onExpand?() }
        let host = UIHostingController(rootView: MiniPlayerView(vm: viewModel))
        host.view.backgroundColor = .clear
        self.host = host
        onAttach?(host, Self.preferredHeight)
    }

    private func detach() {
        guard let host else { return }
        self.host = nil
        onDetach?(host)
    }
}
