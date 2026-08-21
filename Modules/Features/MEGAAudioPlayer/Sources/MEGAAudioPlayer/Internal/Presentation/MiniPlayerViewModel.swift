import Combine
import Foundation
import MEGAL10n

@MainActor
final class MiniPlayerViewModel: ObservableObject {
    var onExpand: (() -> Void)?

    @Published private(set) var title: String = ""
    @Published private(set) var artist: String = ""

    /// The whole queue as identity + title, and the index the service is playing
    @Published private(set) var tracks: [MiniPlayerTrack] = []
    @Published private(set) var currentIndex: Int = 0

    @Published private(set) var loadingState: PlayerLoadingState = .loading

    @Published private(set) var hasActiveSession: Bool = false

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
                self?.artist = artist ?? ""
            }
            .store(in: &cancellables)

        let isReadyPublisher = Publishers.CombineLatest(
            service.artworkResolvedPublisher,
            service.durationPublisher.map { $0 != nil }
        )
        .map { artworkResolved, durationReady in artworkResolved && durationReady }

        Publishers.CombineLatest3(
            service.statusPublisher,
            service.hasStartedPlaybackPublisher,
            isReadyPublisher
        )
        .map { status, hasStartedPlayback, isReady in
            PlayerLoadingState(status: status, hasStartedPlayback: hasStartedPlayback, isReady: isReady)
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.loadingState = $0 }
        .store(in: &cancellables)

        service.currentQueuePublisher
            .sink { [weak self] queue in self?.updateQueue(from: queue) }
            .store(in: &cancellables)

        service.currentSourcePublisher
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] in self?.hasActiveSession = $0 }
            .store(in: &cancellables)
    }

    private func updateQueue(from queue: PlaybackQueue) {
        tracks = queue.tracks.map { MiniPlayerTrack(id: $0.id, title: $0.displayName) }
        currentIndex = queue.currentIndex
    }

    // MARK: - Intents

    func togglePlayPause() {
        guard loadingState.isToggleEnabled else { return }
        service?.togglePlayPause()
    }

    func close() {
        service?.stop()
    }

    func expand() {
        onExpand?()
    }

    func skipToNext() {
        service?.playNext()
    }

    func skipToPrevious() {
        service?.playPrevious()
    }

    // MARK: - Preview / test seeding

    func preview(
        title: String,
        artist: String,
        loadingState: PlayerLoadingState,
        queueTitles: [String] = [],
        currentIndex: Int = 0
    ) {
        self.title = title
        self.artist = artist
        self.loadingState = loadingState
        self.tracks = queueTitles.enumerated().map { MiniPlayerTrack(id: "\($0.offset)", title: $0.element) }
        self.currentIndex = currentIndex
    }
}

/// A queue entry as the mini player needs it: a stable identity for paging and
/// the track's display title.
struct MiniPlayerTrack {
    let id: String
    let title: String
}
