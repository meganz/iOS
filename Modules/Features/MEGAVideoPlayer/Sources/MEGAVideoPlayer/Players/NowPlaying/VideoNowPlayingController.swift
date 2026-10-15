import Combine
import MEGADomain
import MediaPlayer

/// Bridges the video player to the system Now Playing UI (Control Center / lock screen) and its remote commands.
@MainActor
final class VideoNowPlayingController {
    /// Matches the jump buttons on the player overlay.
    static let skipInterval: TimeInterval = 15

    private struct NowPlayingInfo: Equatable {
        let title: String
        let elapsed: TimeInterval
        let duration: TimeInterval
        let rate: Float
    }

    private let player: any VideoPlayerProtocol
    private let infoCenter: any NowPlayingInfoCenterProtocol
    private let commandCenter: any NowPlayingRemoteCommandCenterProtocol
    private let artworkProvider: any VideoNowPlayingArtworkProviding
    private var cancellables: Set<AnyCancellable> = []

    private var lastInfo: NowPlayingInfo?
    private var artwork: MPMediaItemArtwork?
    private(set) var artworkTask: Task<Void, Never>?

    private(set) var isActive = false

    init(
        player: some VideoPlayerProtocol,
        infoCenter: some NowPlayingInfoCenterProtocol = MPNowPlayingInfoCenter.default(),
        commandCenter: some NowPlayingRemoteCommandCenterProtocol = NowPlayingRemoteCommandCenter(),
        artworkProvider: some VideoNowPlayingArtworkProviding = VideoNowPlayingArtworkProvider(
            thumbnailUseCase: DependencyInjection.thumbnailUseCase
        )
    ) {
        self.player = player
        self.infoCenter = infoCenter
        self.commandCenter = commandCenter
        self.artworkProvider = artworkProvider
    }

    deinit {
        artworkTask?.cancel()
    }

    func start() {
        guard !isActive else { return }
        isActive = true

        commandCenter.register(skipInterval: Self.skipInterval) { [weak self] command in
            self?.handle(command)
        }
        bindCommandAvailability()
        bindNowPlayingInfo()
        bindArtwork()
    }

    func stop() {
        guard isActive else { return }
        isActive = false

        cancellables.removeAll()
        artworkTask?.cancel()
        artworkTask = nil
        artwork = nil
        lastInfo = nil
        commandCenter.unregister()
        infoCenter.nowPlayingInfo = nil
    }

    // MARK: - Remote commands

    func handle(_ command: NowPlayingRemoteCommand) {
        guard isActive else { return }

        switch command {
        case .play:
            play()
        case .pause:
            player.pause()
        case .togglePlayPause:
            isPlaybackRequested ? player.pause() : play()
        case .skipForward(let seconds):
            player.jumpForward(by: seconds)
        case .skipBackward(let seconds):
            player.jumpBackward(by: seconds)
        case .nextTrack:
            guard player.canPlayNext else { return }
            player.playNext()
        case .previousTrack:
            player.playPrevious()
        case .changePlaybackPosition(let position):
            player.seek(to: position)
        }
    }

    /// Mirrors the overlay's play button, so resuming from the lock screen recovers the same states.
    private func play() {
        switch player.state {
        case .ended, .stopped:
            player.seek(to: 0)
        case .error:
            player.replayCurrentNode()
            return
        default:
            break
        }

        player.play()
    }

    private var isPlaybackRequested: Bool {
        switch player.state {
        case .playing, .buffering: true
        default: false
        }
    }

    private func bindCommandAvailability() {
        player.canPlayNextPublisher
            .removeDuplicates()
            .sink { [weak self] canPlayNext in
                self?.commandCenter.setEnabled(true, canPlayNext: canPlayNext)
            }
            .store(in: &cancellables)
    }

    // MARK: - Now Playing info

    private func bindNowPlayingInfo() {
        Publishers.CombineLatest4(
            player.nodeNamePublisher,
            player.statePublisher,
            player.durationPublisher,
            player.currentTimePublisher
        )
        .map { [weak self] title, state, duration, currentTime in
            NowPlayingInfo(
                title: title,
                elapsed: max(currentTime.timeInterval, 0),
                duration: duration.timeInterval,
                rate: state == .playing ? self?.player.playbackRate ?? 0 : 0
            )
        }
        .removeDuplicates()
        .sink { [weak self] info in
            self?.lastInfo = info
            self?.update(with: info)
        }
        .store(in: &cancellables)
    }

    private func update(with info: NowPlayingInfo) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: info.title,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: info.elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: info.rate,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
        // The duration stays negative until the item has loaded; an unknown duration is left out rather than shown as zero.
        if info.duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = info.duration
        }
        if let artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        infoCenter.nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Artwork

    /// The node name is republished whenever the player moves to another node, so it doubles as the node change signal.
    private func bindArtwork() {
        player.nodeNamePublisher
            .compactMap { [weak self] _ in self?.player.currentNode }
            .removeDuplicates { $0.handle == $1.handle }
            .sink { [weak self] node in
                self?.loadArtwork(for: node)
            }
            .store(in: &cancellables)
    }

    /// Same as the legacy player: the file type icon right away, replaced by the thumbnail once it is fetched.
    private func loadArtwork(for node: any PlayableNode) {
        artworkTask?.cancel()
        setArtwork(artworkProvider.placeholder(forNodeName: node.name ?? ""))

        let handle = node.handle
        artworkTask = Task { [weak self, artworkProvider] in
            let thumbnail = await artworkProvider.thumbnail(forNodeHandle: handle)
            guard !Task.isCancelled, let self, let thumbnail else { return }
            setArtwork(thumbnail)
        }
    }

    private func setArtwork(_ image: UIImage?) {
        artwork = image.map(Self.makeArtwork)
        if let lastInfo {
            update(with: lastInfo)
        }
    }

    /// Built outside the main actor: MediaPlayer asks for the image from a background thread.
    private nonisolated static func makeArtwork(from image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
