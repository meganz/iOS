import Combine
import SwiftUI

@MainActor
public final class PlayerOverlayViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped
    @Published var currentTime: Duration = .seconds(0)
    @Published var duration: Duration = .seconds(0)

    private let player: any VideoPlayerProtocol
    private let onDismiss: () -> Void

    public init(
        player: some VideoPlayerProtocol,
        onDismiss: @escaping () -> Void
    ) {
        self.player = player
        self.onDismiss = onDismiss
    }

    func viewWillAppear() {
        observePlayer()
    }

    func didTapBack() {
        onDismiss()
    }

    func didTapPlay() {
        switch state {
        case .ended, .stopped:
            player.seek(to: 0)
        default:
            break
        }

        player.play()
    }

    func didTapPause() {
        player.pause()
    }

    func didTapJumpForward() {
        player.jumpForward(by: 10)
    }

    func didTapJumpBackward() {
        player.jumpBackward(by: 10)
    }

    private func observePlayer() {
        observeState()
        observeCurrentTime()
        observeDuration()
    }

    private func observeState() {
        player
           .statePublisher
           .receive(on: DispatchQueue.main)
           .assign(to: &$state)
    }

    private func observeCurrentTime() {
        player
           .currentTimePublisher
           .receive(on: DispatchQueue.main)
           .assign(to: &$currentTime)
    }

    private func observeDuration() {
        player
            .durationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
    }
}

// MARK: - UI Logic

extension PlayerOverlayViewModel {
    var currentTimeString: String {
        string(from: currentTime)
    }

    var durationString: String {
        string(from: duration)
    }
    
    var progress: CGFloat {
        let durationSeconds = duration.components.seconds
        guard durationSeconds > 0 else { return 0 }
        
        let currentSeconds = currentTime.components.seconds
        let result = CGFloat(currentSeconds) / CGFloat(durationSeconds)
        print("progress: \(result)")
        return result
    }

    private func string(from duration: Duration) -> String {
        guard duration.components.seconds >= 0 else { return string(from: .seconds(0)) }

        let secondsInHour = 3600
        if duration.components.seconds > secondsInHour {
            return duration.formatted(
                .time(
                    pattern: .hourMinuteSecond(
                        padHourToLength: 2,
                        roundFractionalSeconds: .towardZero
                    )
                )
            )
        } else {
            return duration.formatted(
                .time(
                    pattern: .minuteSecond(
                        padMinuteToLength: 2,
                        roundFractionalSeconds: .towardZero
                    )
                )
            )
        }
    }
}
