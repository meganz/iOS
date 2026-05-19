import Combine
import Foundation
import SwiftUI

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    // Router-injected callback. Router owns "what dismiss means" (close modal
    // now; later: minimize to mini player). VM stays UI-agnostic — just forwards.
    var onDismiss: (() -> Void)?

    // Router-injected callback for the three-dot button. Router owns presenting
    // the legacy NodeActionViewController; VM only forwards the current source
    // so the new player module stays free of UIKit action-sheet dependencies.
    // Source (not just node) is forwarded so the host can branch between
    // cloud/folder/chat → NodeActionViewController and fileLink →
    // FileLinkActionViewControllerDelegate; offline never reaches the host
    // because the ellipsis is hidden in that case.
    var onMoreTap: ((PlaybackSource) -> Void)?

    @Published private(set) var currentSource: PlaybackSource?

    /// `true` when the three-dot menu should be hidden — matches the legacy
    /// player which hides `moreButton` for offline playback.
    var isActionsMenuHidden: Bool {
        if case .offlineFiles = currentSource { return true }
        return currentSource == nil
    }

    private let service: (any AudioPlaybackServiceProtocol)?
    private var cancellables: Set<AnyCancellable> = []

    /// Preview / placeholder init. No service binding; intents are no-ops.
    init() {
        self.service = nil
    }

    /// Production init. VM mirrors the service's `statePublisher` into its
    /// `@Published` fields and forwards all user intents back to the service.
    init(service: any AudioPlaybackServiceProtocol) {
        self.service = service
        bindService(service)
    }

    private func bindService(_ service: any AudioPlaybackServiceProtocol) {
        service.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.apply(state: state)
            }
            .store(in: &cancellables)
    }

    private func apply(state: AudioPlaybackState?) {
        currentSource = state?.currentSource
    }

    func dismiss() {
        onDismiss?()
    }

    func didTapMore() {
        guard let currentSource else { return }
        onMoreTap?(currentSource)
    }
}
