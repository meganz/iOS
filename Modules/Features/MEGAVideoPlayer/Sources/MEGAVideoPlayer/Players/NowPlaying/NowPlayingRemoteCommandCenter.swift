import MediaPlayer

/// A system remote command (Control Center, lock screen, headphones, CarPlay) the player responds to.
enum NowPlayingRemoteCommand: Equatable, Sendable {
    case play
    case pause
    case togglePlayPause
    case skipForward(TimeInterval)
    case skipBackward(TimeInterval)
    case nextTrack
    case previousTrack
    case changePlaybackPosition(TimeInterval)
}

@MainActor
protocol NowPlayingInfoCenterProtocol: AnyObject {
    var nowPlayingInfo: [String: Any]? { get set }
}

extension MPNowPlayingInfoCenter: NowPlayingInfoCenterProtocol {}

@MainActor
protocol NowPlayingRemoteCommandCenterProtocol: AnyObject {
    /// Starts routing the system remote commands to `handler`. Commands stay disabled until `setEnabled` turns them on.
    func register(
        skipInterval: TimeInterval,
        handler: @escaping @Sendable @MainActor (NowPlayingRemoteCommand) -> Void
    )
    func setEnabled(_ enabled: Bool, canPlayNext: Bool)
    /// Stops routing the commands and disables them, so the system shows no controls for a player that is gone.
    func unregister()
}

@MainActor
final class NowPlayingRemoteCommandCenter: NowPlayingRemoteCommandCenterProtocol {
    private let commandCenter: MPRemoteCommandCenter
    private var targets: [(command: MPRemoteCommand, target: Any)] = []

    init(commandCenter: MPRemoteCommandCenter = .shared()) {
        self.commandCenter = commandCenter
    }

    private var managedCommands: [MPRemoteCommand] {
        [
            commandCenter.playCommand,
            commandCenter.pauseCommand,
            commandCenter.togglePlayPauseCommand,
            commandCenter.skipForwardCommand,
            commandCenter.skipBackwardCommand,
            commandCenter.nextTrackCommand,
            commandCenter.previousTrackCommand,
            commandCenter.changePlaybackPositionCommand
        ]
    }

    func register(
        skipInterval: TimeInterval,
        handler: @escaping @Sendable @MainActor (NowPlayingRemoteCommand) -> Void
    ) {
        unregister()

        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: skipInterval)]
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipInterval)]

        addTarget(to: commandCenter.playCommand, handler: handler) { _ in .play }
        addTarget(to: commandCenter.pauseCommand, handler: handler) { _ in .pause }
        addTarget(to: commandCenter.togglePlayPauseCommand, handler: handler) { _ in .togglePlayPause }
        addTarget(to: commandCenter.skipForwardCommand, handler: handler) { event in
            (event as? MPSkipIntervalCommandEvent).map { .skipForward($0.interval) }
        }
        addTarget(to: commandCenter.skipBackwardCommand, handler: handler) { event in
            (event as? MPSkipIntervalCommandEvent).map { .skipBackward($0.interval) }
        }
        addTarget(to: commandCenter.nextTrackCommand, handler: handler) { _ in .nextTrack }
        addTarget(to: commandCenter.previousTrackCommand, handler: handler) { _ in .previousTrack }
        addTarget(to: commandCenter.changePlaybackPositionCommand, handler: handler) { event in
            (event as? MPChangePlaybackPositionCommandEvent).map { .changePlaybackPosition($0.positionTime) }
        }
    }

    func setEnabled(_ enabled: Bool, canPlayNext: Bool) {
        managedCommands.forEach { $0.isEnabled = enabled }
        commandCenter.nextTrackCommand.isEnabled = enabled && canPlayNext
    }

    func unregister() {
        targets.forEach { $0.command.removeTarget($0.target) }
        targets.removeAll()
        setEnabled(false, canPlayNext: false)
    }

    private func addTarget(
        to command: MPRemoteCommand,
        handler: @escaping @Sendable @MainActor (NowPlayingRemoteCommand) -> Void,
        map: @escaping @Sendable (MPRemoteCommandEvent) -> NowPlayingRemoteCommand?
    ) {
        let target = command.addTarget(handler: Self.makeHandler(map: map, handler: handler))
        targets.append((command, target))
    }

    /// Built outside the main actor: MediaPlayer gives no isolation guarantee for the thread it calls handlers on.
    private nonisolated static func makeHandler(
        map: @escaping @Sendable (MPRemoteCommandEvent) -> NowPlayingRemoteCommand?,
        handler: @escaping @Sendable @MainActor (NowPlayingRemoteCommand) -> Void
    ) -> (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        { event in
            guard event.command.isEnabled, let command = map(event) else { return .commandFailed }
            Task { @MainActor in handler(command) }
            return .success
        }
    }
}
