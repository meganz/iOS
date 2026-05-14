import Combine
import Foundation
import SwiftUI

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    // Router-injected callback. Router owns "what dismiss means" (close modal
    // now; later: minimize to mini player). VM stays UI-agnostic — just forwards.
    var onDismiss: (() -> Void)?

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

    private func apply(state: AudioPlaybackState) {
    }

    func dismiss() {
        onDismiss?()
    }
}
