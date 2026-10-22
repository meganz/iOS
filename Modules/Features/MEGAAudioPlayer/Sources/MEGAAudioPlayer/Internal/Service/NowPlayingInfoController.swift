import Combine
import MediaPlayer
import UIKit

/// Bridges playback state to the system Now Playing UI (Control Center / lock screen)
@MainActor
final class NowPlayingInfoController {
    struct Commands {
        let togglePlayPause: () -> Void
        let next: () -> Void
        let previous: () -> Void
        let seek: (TimeInterval) -> Void
    }
    
    private struct NowPlayingInfo: Equatable {
        let elapsed: TimeInterval
        let rate: Float
        let duration: TimeInterval
        let title: String
        let artist: String
        let artworkData: Data?
    }

    private let infoCenter: MPNowPlayingInfoCenter
    private let commandCenter: MPRemoteCommandCenter
    private let commands: Commands

    private var cancellables: Set<AnyCancellable> = []

    private var hasSource = false {
        didSet {
            // While suspended the shared commands and info belong to another player
            guard !isSuspended else { return }
            applyActivity()
        }
    }

    /// Set while another player owns the shared remote commands and Now Playing info.
    private var isSuspended = false

    private var isActive: Bool { hasSource && !isSuspended }

    private var lastInfo: NowPlayingInfo?

    private var rate: Float { lastInfo?.rate ?? 0 }

    private var managedCommands: [MPRemoteCommand] {
        [
            commandCenter.playCommand,
            commandCenter.pauseCommand,
            commandCenter.togglePlayPauseCommand,
            commandCenter.nextTrackCommand,
            commandCenter.previousTrackCommand,
            commandCenter.changePlaybackPositionCommand
        ]
    }

    init(
        commands: Commands,
        infoCenter: MPNowPlayingInfoCenter = .default(),
        commandCenter: MPRemoteCommandCenter = .shared()
    ) {
        self.commands = commands
        self.infoCenter = infoCenter
        self.commandCenter = commandCenter
        registerCommands()
    }

    func observe(_ state: some PlaybackStateObservable) {
        state.currentSourcePublisher
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] hasSource in self?.hasSource = hasSource }
            .store(in: &cancellables)

        let content = Publishers.CombineLatest3(
            state.titlePublisher,
            state.artistPublisher.map { $0 ?? "" },
            state.playbackRatePublisher
        )
        let timing = Publishers.CombineLatest3(
            state.durationPublisher.map { $0 ?? 0 },
            state.currentTimePublisher,
            state.artworkDataPublisher
        )
        Publishers.CombineLatest(content, timing)
            .map { content, timing in
                let (title, artist, rate) = content
                let (duration, elapsed, artworkData) = timing
                return NowPlayingInfo(
                    elapsed: elapsed,
                    rate: rate,
                    duration: duration,
                    title: title,
                    artist: artist,
                    artworkData: artworkData
                )
            }
            .debounce(for: .zero, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] info in
                guard let self else { return }
                lastInfo = info
                guard isActive else { return }
                publish(info)
            }
            .store(in: &cancellables)
    }

    /// Hands the remote commands and Now Playing info over to another player.
    func suspend() {
        guard !isSuspended else { return }
        let wasActive = isActive
        isSuspended = true
        if wasActive { applyActivity() }
    }

    /// Takes the remote commands back and restores the last Now Playing info.
    func resume() {
        guard isSuspended else { return }
        isSuspended = false
        // Also applied without a source: don't rely on the other player having disabled the shared commands
        applyActivity()
        if isActive, let lastInfo { publish(lastInfo) }
    }

    private func applyActivity() {
        setCommandsEnabled(isActive)
        if !isActive { infoCenter.nowPlayingInfo = nil }
    }

    private func publish(_ info: NowPlayingInfo) {
        var dict: [String: Any] = [
            MPMediaItemPropertyTitle: info.title,
            MPMediaItemPropertyArtist: info.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: info.elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: info.rate
        ]
        if let image = info.artworkData.flatMap(UIImage.init(data:)) {
            dict[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in image }
        }
        if info.duration > 0 {
            dict[MPMediaItemPropertyPlaybackDuration] = info.duration
        }
        infoCenter.nowPlayingInfo = dict
    }

    // MARK: - Remote commands

    private func registerCommands() {
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.handle(event) { $0.commands.togglePlayPause() } ?? .commandFailed
        }
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.handle(event) { if $0.rate == 0 { $0.commands.togglePlayPause() } } ?? .commandFailed
        }
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.handle(event) { if $0.rate != 0 { $0.commands.togglePlayPause() } } ?? .commandFailed
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.handle(event) { $0.commands.next() } ?? .commandFailed
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.handle(event) { $0.commands.previous() } ?? .commandFailed
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let position = event.positionTime
            return self?.handle(event) { $0.commands.seek(position) } ?? .commandFailed
        }
    }

    private nonisolated func handle(
        _ event: MPRemoteCommandEvent,
        _ action: @escaping @MainActor (NowPlayingInfoController) -> Void
    ) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled else { return .commandFailed }
        Task { @MainActor [weak self] in
            // The commands are shared: another player that enabled them is not asking this one
            guard let self, isActive else { return }
            action(self)
        }
        return .success
    }

    private func setCommandsEnabled(_ enabled: Bool) {
        managedCommands.forEach { $0.isEnabled = enabled }
    }
}
