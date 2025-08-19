import Combine
import SwiftUI

@MainActor
public final class PlayerOverlayViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped

    @Published var currentTime: Duration = .seconds(0)
    @Published var duration: Duration = .seconds(0)
    
    @Published var isLoading: Bool = true
    @Published var isControlsVisible: Bool = false
    @Published var currentSpeed: PlaybackSpeed = .normal
    @Published var isLoopEnabled: Bool = false

    private var autoHideTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let player: any VideoPlayerProtocol
    private let didTapBackAction: () -> Void

    public init(
        player: some VideoPlayerProtocol,
        didTapBackAction: @escaping () -> Void
    ) {
        self.player = player
        self.didTapBackAction = didTapBackAction
    }

    func viewWillAppear() {
        observePlayer()
    }

    func didTapBack() {
        didTapBackAction()
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
           .sink { [weak self] newState in
               self?.handleStateChange(newState)
           }
           .store(in: &cancellables)
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

// MARK: - Center controls logic

extension PlayerOverlayViewModel {
    func didTapPlay() {
        switch state {
        case .ended, .stopped:
            player.seek(to: 0)
        default:
            break
        }

        player.play()
        didTapControl()
    }

    func didTapPause() {
        player.pause()
        didTapControl()
    }

    func didTapJumpForward() {
        player.jumpForward(by: 10)
        didTapControl()
    }

    func didTapJumpBackward() {
        player.jumpBackward(by: 10)
        didTapControl()
    }
}

// MARK: - Timeline logic

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

// MARK: - Bottom controls logic

extension PlayerOverlayViewModel {
    func didTapPlaybackSpeed() {
        let nextSpeed = currentSpeed.next()
        player.changeRate(to: nextSpeed.rawValue)
        currentSpeed = nextSpeed
        didTapControl()
    }

    var currentSpeedString: String {
        currentSpeed.displayText
    }
    
    func didTapLoopButton() {
        isLoopEnabled.toggle()
        player.setLooping(isLoopEnabled)
        didTapControl()
    }
}

// MARK: - Overlay Visibility Management

extension PlayerOverlayViewModel {
    func showControls() {
        isControlsVisible = true
        if shouldAutoHide {
            startAutoHideTimer()
        }
    }

    func hideControls() {
        isControlsVisible = false
        cancelAutoHideTimer()
    }

    func didTapVideoArea() {
        if isControlsVisible {
            hideControls()
        } else {
            showControls()
        }
    }

    private func didTapControl() {
        guard shouldAutoHide else { return }
        startAutoHideTimer()
    }

    private func startAutoHideTimer() {
        cancelAutoHideTimer()

        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideControls()
            }
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private var shouldAutoHide: Bool {
        switch state {
        case .paused:
            return false
        case .playing, .buffering, .opening, .stopped, .ended, .error:
            return true
        }
    }

    private func handleStateChange(_ newState: PlaybackState) {
        state = newState
        switch newState {
        case .opening, .buffering:
            isLoading = true
        case .playing, .paused, .ended, .error, .stopped:
            isLoading = false
        }
    }
}
