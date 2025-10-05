import Combine
import MEGAInfrastructure
import MEGAL10n
import MEGAPermissions
import Photos
import SwiftUI

@MainActor
public final class PlayerOverlayViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped

    @Published var currentTime: Duration = .seconds(0)
    @Published var duration: Duration = .seconds(0)
    @Published var canPlayNext = false

    @Published var title: String = ""
    @Published var isControlsVisible: Bool = true
    @Published var currentSpeed: PlaybackSpeed = .normal
    @Published var isLoopEnabled: Bool = false
    @Published var isPlaybackBottomSheetPresented: Bool = false
    @Published var isBottomMoreSheetPresented: Bool = false
    @Published var scalingMode: VideoScalingMode = .fit
    @Published var isSeeking: Bool = false
    @Published var shouldShowHoldToSpeedChip: Bool = false
    @Published var isDoubleTapSeekActive: Bool = false
    @Published var doubleTapSeekSeconds: Int = 0
    @Published var isLocked: Bool = false
    @Published var isLockOverlayVisible: Bool = false
    @Published var showSnapshotSuccessMessage: Bool = false
    private(set) var shouldShowPhotoPermissionAlert = false
    private var isHoldToSpeed = false
    private var autoHideTimer: Timer?
    private var doubleTapSeekTimer: Timer?
    private var lockOverlayTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let player: any VideoPlayerProtocol
    private let devicePermissionsHandler: any DevicePermissionsHandling
    private let saveSnapshotUseCase: any SaveSnapshotUseCaseProtocol
    private let hapticFeedbackUseCase: any HapticFeedbackUseCaseProtocol
    private let didTapBackAction: () -> Void
    private let didTapMoreAction: ((any PlayableNode)?) -> Void
    private let didTapRotateAction: () -> Void
    private let didTapPictureInPictureAction: () -> Void

    public init(
        player: some VideoPlayerProtocol,
        devicePermissionsHandler: some DevicePermissionsHandling,
        saveSnapshotUseCase: some SaveSnapshotUseCaseProtocol,
        hapticFeedbackUseCase: some HapticFeedbackUseCaseProtocol,
        didTapBackAction: @escaping () -> Void,
        didTapMoreAction: @escaping ((any PlayableNode)?) -> Void,
        didTapRotateAction: @escaping () -> Void = {},
        didTapPictureInPictureAction: @escaping () -> Void = {}
    ) {
        self.player = player
        self.devicePermissionsHandler = devicePermissionsHandler
        self.saveSnapshotUseCase = saveSnapshotUseCase
        self.hapticFeedbackUseCase = hapticFeedbackUseCase
        self.didTapBackAction = didTapBackAction
        self.didTapMoreAction = didTapMoreAction
        self.didTapRotateAction = didTapRotateAction
        self.didTapPictureInPictureAction = didTapPictureInPictureAction
    }

    func viewWillAppear() {
        observePlayer()
    }

    private func observePlayer() {
        observeState()
        observeCurrentTime()
        observeDuration()
        observeCanPlayNext()
        observeNodeName()
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
           .sink { [weak self] newTime in
               guard let self, !isSeeking else { return }
               currentTime = newTime
           }
           .store(in: &cancellables)
    }

    private func observeDuration() {
        player
            .durationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
    }

    private func observeCanPlayNext() {
        player
            .canPlayNextPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$canPlayNext)
    }

    private func observeNodeName() {
        player
            .nodeNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$title)
    }
}

// MARK: - nav bar logic

extension PlayerOverlayViewModel {
    func didTapBack() {
        didTapBackAction()
    }

    func didTapMore() {
        didTapMoreAction(player.currentNode)
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
        resetAutoHide()
    }

    func didTapPause() {
        player.pause()
        resetAutoHide()
    }

    func didTapJump(by second: Int) async {
        await performSeek(by: second)
    }

    func performSeek(by seekTime: Int) async {
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        updateCurrentTimeForSeek(by: seekTime)
        guard await seekToCurrentTime() else { return }
        // Slight delay to ensure current time updates correctly after seeking
        try? await Task.sleep(nanoseconds: 100_000_000)
        isSeeking = false
        resetAutoHide()
    }

    func didTapPlayPrevious() {
        player.playPrevious()
    }

    func didTapPlayNext() {
        player.playNext()
    }
}

// MARK: - Timeline logic

extension PlayerOverlayViewModel {
    var currentTimeAndDurationString: String {
        let currentTimeString = string(from: currentTime)
        let durationString = string(from: duration)
        return "\(currentTimeString) / \(durationString)"
    }

    var progress: CGFloat {
        let durationSeconds = duration.components.seconds
        guard durationSeconds > 0 else { return 0 }

        let currentSeconds = currentTime.components.seconds
        let result = CGFloat(currentSeconds) / CGFloat(durationSeconds)
        let finalResult = min(result, 1.0)
        return finalResult
    }

    func updateSeekBarDrag(at location: CGPoint, in frame: CGRect) {
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        currentTime = calculateTargetTime(from: location.x, in: frame.width)
    }

    func endSeekBarDrag(at location: CGPoint, in frame: CGRect) async {
        let seekTimeInDuration = calculateSeekTime(from: location.x, in: frame.width)
        let seekTime = Int(seekTimeInDuration.components.seconds)
        await performSeek(by: seekTime)
    }

    private func calculateTargetTime(
        from xPosition: CGFloat,
        in width: CGFloat
    ) -> Duration {
        let durationInSeconds = duration.components.seconds
        guard durationInSeconds > 0 else { return .seconds(0) }
        let clampedX = max(0, min(xPosition, width))
        let progress = clampedX / width
        let finalProgress = max(0, min(progress, 1.0))
        let targetTime = finalProgress * Double(durationInSeconds)
        return Duration.milliseconds(targetTime * 1000)
    }

    private func calculateSeekTime(
        from xPosition: CGFloat,
        in width: CGFloat
    ) -> Duration {
        let targetTime = calculateTargetTime(from: xPosition, in: width)
        return targetTime - currentTime
    }

    private func updateCurrentTimeForSeek(by seconds: Int) {
        guard duration.components.seconds > 0 else { return }
        let seekTimeInDuration = Duration.seconds(seconds)
        let targetTime = currentTime + seekTimeInDuration
        let finalTargetTime = max(.seconds(0), min(targetTime, duration))
        currentTime = finalTargetTime
    }

    private func seekToCurrentTime() async -> Bool {
        let timeInSeconds = currentTime.components.seconds
        return await player.seek(to: Double(timeInSeconds))
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
        isPlaybackBottomSheetPresented = true
        resetAutoHide()
    }

    func didSelectPlaybackSpeed(_ speed: PlaybackSpeed) {
        currentSpeed = speed
        player.changeRate(to: speed.rawValue)
        isPlaybackBottomSheetPresented = false
    }

    var currentSpeedString: String {
        currentSpeed.displayText
    }

    func didTapLoopButton() {
        isLoopEnabled.toggle()
        player.setLooping(isLoopEnabled)
        resetAutoHide()
    }

    func didTapRotate() {
        didTapRotateAction()
        resetAutoHide()
    }
    
    func didTapScalingButton() {
        scalingMode = scalingMode.toggled()
        player.setScalingMode(scalingMode)
        resetAutoHide()
    }

    func didTapBottomMoreButton() {
        isBottomMoreSheetPresented = true
    }

    func didTapPictureInPicture() {
        isBottomMoreSheetPresented = false
        didTapPictureInPictureAction()
        resetAutoHide()
    }

    func handlePinchGesture(scale: CGFloat) {
        let threshold: CGFloat = 1.0
        
        if scale > threshold {
            // Pinch out - switch to fill mode
            if scalingMode != .fill {
                scalingMode = .fill
                player.setScalingMode(.fill)
            }
        } else if scale < threshold {
            // Pinch in - switch to fit mode
            if scalingMode != .fit {
                scalingMode = .fit
                player.setScalingMode(.fit)
            }
        }
    }
    
    // MARK: - Lock functionality

    func didTapLock() {
        isBottomMoreSheetPresented = false
        activateLock()
    }

    private func activateLock() {
        isLocked = true
        isLockOverlayVisible = true
        hideControls()
        startLockOverlayTimer()
    }
    
    private func deactivateLock() {
        isLocked = false
        isLockOverlayVisible = false
        cancelLockOverlayTimer()
        showControls()
    }
    
    func didTapDeactivateLock() {
        deactivateLock()
    }
    
    func didTapVideoAreaWhileLocked() {
        if isLockOverlayVisible {
            isLockOverlayVisible = false
            cancelLockOverlayTimer()
        } else {
            isLockOverlayVisible = true
            startLockOverlayTimer()
        }
    }
    
    private func startLockOverlayTimer() {
        cancelLockOverlayTimer()
        
        lockOverlayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isLockOverlayVisible = false
            }
        }
    }
    
    private func cancelLockOverlayTimer() {
        lockOverlayTimer?.invalidate()
        lockOverlayTimer = nil
    }
}

// MARK: - Snapshot functionality

extension PlayerOverlayViewModel {
    func didTapSnapshot() async {
        isBottomMoreSheetPresented = false
        let isPhotoPermissionGranted = await  devicePermissionsHandler.requestPhotoLibraryAddOnlyPermissions()
        if isPhotoPermissionGranted {
            guard let image = await player.captureSnapshot() else { return }
            await saveImageToGallery(image)
        } else {
            shouldShowPhotoPermissionAlert = true
        }
    }

    private func saveImageToGallery(_ image: UIImage) async {
        guard await saveSnapshotUseCase.saveToPhotoLibrary(image) else {
            return
        }
        showSnapshotSuccessMessage = true
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        showSnapshotSuccessMessage = false
    }

    func checkToShowPhotoPermissionAlert() {
        defer { shouldShowPhotoPermissionAlert = false}
        guard shouldShowPhotoPermissionAlert else { return }
        showPhotoPermissionAlert()
    }

    private func showPhotoPermissionAlert() {
        // When SwiftUI is embedded in UIKit, UIKit's presentation system takes over
        // Use UIKit alert presentation instead
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }

        let alert = UIAlertController(
            title: Strings.Localizable.attention,
            message: Strings.Localizable.photoLibraryPermissions,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Strings.Localizable.notNow, style: .cancel))

        alert.addAction(UIAlertAction(title: Strings.Localizable.settingsTitle, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(url)
        })

        topController.present(alert, animated: true)
    }
}

// MARK: - Hold to Speed logic

extension PlayerOverlayViewModel {
    func beginHoldToSpeed() {
        guard duration.components.seconds > 0,
              state == .playing else {
            return
        }
        isHoldToSpeed = true
        if currentSpeed != .double {
            hapticFeedbackUseCase.generateHapticFeedback(.light)
            shouldShowHoldToSpeedChip = true
        }
        player.changeRate(to: PlaybackSpeed.double.rawValue)
        isControlsVisible = false
    }

    func endHoldToSpeed() {
        guard duration.components.seconds > 0,
              isHoldToSpeed else {
            return
        }
        shouldShowHoldToSpeedChip = false
        player.changeRate(to: currentSpeed.rawValue)
    }
}

// MARK: - Double Tap Seek logic

extension PlayerOverlayViewModel {
    func handleDoubleTapSeek(isForward: Bool) async {
        guard duration.components.seconds > 0 else { return }
        hapticFeedbackUseCase.generateHapticFeedback(.light)
        isDoubleTapSeekActive = true
        let seekTime = isForward ? 15 : -15

        let isSameDirection = (seekTime >= 0 && doubleTapSeekSeconds >= 0) || (seekTime < 0 && doubleTapSeekSeconds < 0)

        if isSameDirection {
            doubleTapSeekSeconds += seekTime
        } else {
            doubleTapSeekSeconds = seekTime
        }

        await performSeek(by: seekTime)

        startDoubleTapSeekTimer()
    }
    
    private func startDoubleTapSeekTimer() {
        cancelDoubleTapSeekTimer()
        
        doubleTapSeekTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endDoubleTapSeek()
            }
        }
    }
    
    private func cancelDoubleTapSeekTimer() {
        doubleTapSeekTimer?.invalidate()
        doubleTapSeekTimer = nil
    }
    
    private func endDoubleTapSeek() {
        isDoubleTapSeekActive = false
        doubleTapSeekSeconds = 0
        cancelDoubleTapSeekTimer()
    }
    
    var doubleTapSeekDisplayText: String {
        let seconds = abs(doubleTapSeekSeconds)
        return Strings.Localizable.VideoPlayer.Chip.seekDisplayText(seconds)
    }

    func doubleTapSeekChipBottomPadding(isLandscape: Bool) -> CGFloat {
        if isControlsVisible {
            isLandscape ? 102 : 188
        } else {
            48
        }
    }
}

// MARK: - Overlay Visibility Management

extension PlayerOverlayViewModel {
    func showControls() {
        guard !isLocked else { return }
        isControlsVisible = true
        resetAutoHide()
    }

    func hideControls() {
        isControlsVisible = false
        cancelAutoHideTimer()
    }

    func didTapVideoArea() {
        if isLocked {
            didTapVideoAreaWhileLocked()
        } else {
            if isControlsVisible {
                hideControls()
            } else {
                showControls()
            }
        }
    }

    private func resetAutoHide() {
        if shouldAutoHide {
            startAutoHideTimer()
        } else {
            cancelAutoHideTimer()
        }
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
        case .paused, .buffering, .ended:
            false
        case .playing, .opening, .stopped, .error:
            true
        }
    }

    private func handleStateChange(_ newState: PlaybackState) {
        state = newState
        switch newState {
        case .opening, .ended:
            showControls()
        default:
            break
        }
        resetAutoHide()
    }

    var shouldShownJumpButtons: Bool {
        duration.components.seconds > 0
    }
}
