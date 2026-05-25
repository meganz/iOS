import Combine
import Foundation
import MEGAL10n
import SwiftUI

@MainActor
final class MiniPlayerViewModel: ObservableObject {
    var onExpand: (() -> Void)?

    @Published private(set) var title: String = ""
    @Published private(set) var artist: String = ""
    @Published private(set) var status: PlaybackStatus = .loading

    private let service: (any AudioPlaybackServiceProtocol)?
    private var cancellables: Set<AnyCancellable> = []

    /// Preview / placeholder init. No service binding; intents are no-ops and
    /// the published fields stay at their defaults unless seeded via `preview`.
    init() {
        self.service = nil
    }

    /// Production init. Mirrors the service's `statePublisher` into the
    /// `@Published` fields and forwards user intents back to the service.
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
        guard let state else { return }
        status = state.status
        title = state.title
        artist = state.artist ?? Strings.Localizable.Media.Audio.Metadata.Missing.artist
    }

    // MARK: - Intents

    func togglePlayPause() {
        guard status != .loading else { return }
        service?.togglePlayPause()
    }

    func close() {
        service?.stop()
    }

    func expand() {
        onExpand?()
    }

    // MARK: - Preview / test seeding

    func preview(title: String, artist: String, status: PlaybackStatus) {
        self.title = title
        self.artist = artist
        self.status = status
    }
}
