import Combine
import Foundation
import MEGAL10n
import SwiftUI

@MainActor
final class MiniPlayerViewModel: ObservableObject {
    var onExpand: (() -> Void)?

    @Published private(set) var title: String = ""
    @Published private(set) var artist: String = ""

    @Published private(set) var loadingState: PlayerLoadingState = .loading

    var isPreparing: Bool { loadingState == .loading || loadingState == .ready }

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

        let isReadyPublisher = Publishers.CombineLatest(
            service.artworkResolvedPublisher,
            service.durationPublisher.map { $0 != nil }
        )
        .map { artworkResolved, durationReady in artworkResolved && durationReady }

        Publishers.CombineLatest3(
            service.statusPublisher,
            service.hasPlayedOnceBeforePublisher,
            isReadyPublisher
        )
        .map { status, hasPlayedOnceBefore, isReady in
            PlayerLoadingState(status: status, hasPlayedOnceBefore: hasPlayedOnceBefore, isReady: isReady)
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.loadingState = $0 }
        .store(in: &cancellables)
    }

    // MARK: - Intents

    func togglePlayPause() {
        guard !isPreparing else { return }
        service?.togglePlayPause()
    }

    func close() {
        service?.stop()
    }

    func expand() {
        onExpand?()
    }

    // MARK: - Preview / test seeding

    func preview(title: String, artist: String, loadingState: PlayerLoadingState) {
        self.title = title
        self.artist = artist
        self.loadingState = loadingState
    }
}
