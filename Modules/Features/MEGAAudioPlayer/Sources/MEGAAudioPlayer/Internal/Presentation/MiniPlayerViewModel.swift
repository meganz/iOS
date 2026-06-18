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

    /// Production init. Mirrors the service's state publishers into the
    /// `@Published` fields and forwards user intents back to the service.
    init(service: any AudioPlaybackServiceProtocol) {
        self.service = service
        bindService(service)
    }

    private func bindService(_ service: any AudioPlaybackServiceProtocol) {
        service.titlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.title = $0 }
            .store(in: &cancellables)

        service.artistPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] artist in
                self?.artist = artist ?? Strings.Localizable.Media.Audio.Metadata.Missing.artist
            }
            .store(in: &cancellables)

        service.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.status = $0 }
            .store(in: &cancellables)
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
