import Combine
import SwiftUI

@MainActor
final class PlayerOverlayViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped
    @Published var currentTime: Duration = .seconds(0)
    @Published var duration: Duration = .seconds(0)

    private let player: any VideoPlayerProtocol

    init(player: some VideoPlayerProtocol) {
        self.player = player
    }

    func viewWillAppear() {
        observePlayer()
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

    private func string(from duration: Duration) -> String {
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
