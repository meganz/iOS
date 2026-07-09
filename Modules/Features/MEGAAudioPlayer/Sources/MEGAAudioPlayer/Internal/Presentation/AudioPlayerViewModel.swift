import Combine
import Foundation
import SwiftUI
import UIKit

enum SeekDirection: Equatable {
    case backward
    case forward
}

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    // Router-injected callback. Router owns "what dismiss means" (close modal
    // now; later: minimize to mini player). VM stays UI-agnostic — just forwards.
    var onDismiss: (() -> Void)?

    // Router-injected callback for the three-dot button.
    var onMoreTap: ((PlaybackSource) -> Void)?

    @Published private(set) var currentSource: PlaybackSource?

    /// Cover-art bytes parsed from the file's embedded tags
    @Published private(set) var artworkData: Data?

    /// Downloaded cover artwork for the current track. `nil` when the file has
    /// no detectable cover image — in that case the View falls back to the
    /// placeholder icon and skips the glow layer.
    @Published private(set) var artworkImage: UIImage?

    /// Dominant tint extracted from `artworkImage`. Pre-computed at download
    /// time so the View stays free of Core Image work.
    @Published private(set) var glowColor: Color?

    /// Track title rendered above the scrubber.
    @Published private(set) var title: String?

    /// Track artist rendered below the title.
    @Published private(set) var artist: String?

    /// Current playback position in seconds.
    @Published private(set) var currentTime: TimeInterval = 0

    /// Track total duration. 
    @Published private(set) var duration: TimeInterval?

    @Published private(set) var playbackMode: PlaybackMode = .music

    @Published private(set) var loadingState: PlayerLoadingState = .loading

    @Published private(set) var isAirPlayActive: Bool = false

    // MARK: - Music Mode state

    @Published private(set) var isShuffleOn: Bool = false

    @Published private(set) var repeatMode: RepeatMode = .off

    // MARK: - Podcast Mode state

    /// Available podcast playback speeds, in display order.
    let playbackSpeedOptions: [Float] = [2, 1.75, 1.5, 1.25, 1, 0.75, 0.5, 0.25]

    @Published private(set) var playbackSpeed: Float = 1

    @Published private(set) var sleepTimerState: SleepTimerState = .inactive

    var isSleepTimerActive: Bool { sleepTimerState.isActive }

    // MARK: - Double-tap seek feedback

    @Published private(set) var visibleSeekFeedback: SeekDirection?

    /// Seek distance for a single skip / double-tap, in seconds.
    let skipInterval: TimeInterval = 15

    private static let seekFeedbackDuration: TimeInterval = 0.8

    private var seekFeedbackTask: Task<Void, Never>?

    // MARK: - Playlist state

    @Published private(set) var isPlaylistVisible: Bool = false

    @Published private(set) var playlistItems: [AudioPlaylistItem] = []

    @Published private(set) var currentTrackID: String?

    var isQueueButtonEnabled: Bool {
        switch currentSource {
        case .fileLink, .searchResult, .chatMessage, .none:
            false
        case .allAudios, .cloudNode, .folderLink, .offlineFiles, .recents:
            true
        }
    }

    /// `true` when the three-dot menu should be hidden — matches the legacy
    /// player which hides `moreButton` for offline playback.
    var isActionsMenuHidden: Bool {
        if case .offlineFiles = currentSource { return true }
        return currentSource == nil
    }

    private let service: (any AudioPlaybackServiceProtocol)?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Skip-back double-tap detection

    /// A second skip-back tap within this window of the previous one goes to the
    /// previous track; otherwise a tap restarts the current track.
    private static let skipPreviousDoubleTapWindow: Duration = .seconds(0.3)

    private let now: () -> ContinuousClock.Instant

    /// Timestamp of the last skip-back tap, or `nil` once a tap has been paired
    /// into a "previous track" action (so the next tap starts fresh).
    private var lastSkipPreviousTap: ContinuousClock.Instant?

    /// Preview / placeholder init. No service binding; intents are no-ops.
    init() {
        self.service = nil
        self.now = { ContinuousClock().now }
    }

    deinit {
        seekFeedbackTask?.cancel()
    }

    init(
        service: any AudioPlaybackServiceProtocol,
        now: @escaping () -> ContinuousClock.Instant = { ContinuousClock().now }
    ) {
        self.service = service
        self.now = now
        bindService(service)
    }

    private func bindService(_ service: any AudioPlaybackServiceProtocol) {
        service.currentSourcePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSource)

        service.currentQueuePublisher
            .map(\.tracks)
            .removeDuplicates { $0.map(\.id) == $1.map(\.id) }
            .map { tracks in
                tracks.map { AudioPlaylistItem(id: $0.id, title: $0.displayName, artist: nil, thumbnail: nil) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self, self.playlistItems.map(\.id) != items.map(\.id) else { return }
                self.playlistItems = items
            }
            .store(in: &cancellables)

        service.currentQueuePublisher
            .map { $0.current?.id }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTrackID)

        service.titlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.title = $0 }
            .store(in: &cancellables)

        service.artistPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$artist)

        service.artworkDataPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$artworkData)

        service.currentTimePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTime)

        service.durationPublisher
            .map { duration in duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil } }
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)

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
        .assign(to: &$loadingState)

        service.isAirPlayActivePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAirPlayActive)

        service.isShuffleOnPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isShuffleOn)

        service.playbackSpeedPublisher
            .assign(to: &$playbackSpeed)

        service.repeatModePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$repeatMode)

        service.sleepTimerStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepTimerState)
    }

    /// Decode the current track's embedded cover (`artworkData`, parsed from the
    /// file's ID3 / MP4 tags) into an image + dominant glow color
    func loadArtwork() async {
        guard let artworkData else {
            artworkImage = nil
            glowColor = nil
            return
        }

        let result = await decodeArtwork(from: artworkData)
        guard !Task.isCancelled else { return }
        artworkImage = result?.image
        glowColor = result?.color
    }

    /// Decode embedded cover bytes into an image and its dominant glow tint
    nonisolated private func decodeArtwork(from data: Data) async -> (image: UIImage, color: Color?)? {
        guard !Task.isCancelled, let image = UIImage(data: data) else { return nil }
        let color = image.mnz_dominantColor.map(Color.init(uiColor:))
        return (image, color)
    }

    func dismiss() {
        onDismiss?()
    }

    func didTapMore() {
        guard let currentSource else { return }
        onMoreTap?(currentSource)
    }

    /// Seed `artworkImage` + `glowColor` directly. Normally driven by the
    /// `loadArtwork()` decode pipeline; exposed for tests / preview.
    func setArtwork(image: UIImage?, glowColor: Color?) {
        artworkImage = image
        self.glowColor = glowColor
    }

    /// Seed the Music Mode control-layout fields directly. Same purpose as
    /// `setArtwork(image:glowColor:)` — gives previews and tests something
    /// to render against until the audio engine wires real state in.
    func setControlState(
        title: String? = nil,
        artist: String? = nil,
        currentTime: TimeInterval = 0,
        duration: TimeInterval? = nil,
        loadingState: PlayerLoadingState = .loading,
        isShuffleOn: Bool = false,
        repeatMode: RepeatMode = .off,
        playbackMode: PlaybackMode = .music,
        playbackSpeed: Float = 1,
        isAirPlayActive: Bool = false,
        sleepTimerState: SleepTimerState = .inactive
    ) {
        self.title = title
        self.artist = artist
        self.currentTime = currentTime
        self.duration = duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        self.loadingState = loadingState
        self.isShuffleOn = isShuffleOn
        self.repeatMode = repeatMode
        self.playbackMode = playbackMode
        self.playbackSpeed = playbackSpeed
        self.isAirPlayActive = isAirPlayActive
        self.sleepTimerState = sleepTimerState
    }

    // MARK: - Music Mode intents

    func togglePlayPause() {
        service?.togglePlayPause()
    }

    func skipPrevious() {
        guard let service else { return }
        let tap = now()
        let isFollowUpTap = lastSkipPreviousTap
            .map { tap - $0 <= Self.skipPreviousDoubleTapWindow } ?? false

        if isFollowUpTap {
            lastSkipPreviousTap = nil
            service.playPrevious()
        } else {
            lastSkipPreviousTap = tap
            service.seek(toSeconds: 0)
        }
    }

    func skipNext() {
        service?.playNext()
    }

    func toggleShuffle() {
        service?.toggleShuffle()
    }

    func cycleRepeat() {
        service?.cycleRepeat()
    }

    func seek(toFraction fraction: Double) {
        guard let duration, fraction.isFinite, fraction >= 0 else { return }
        seek(toSeconds: max(0, min(fraction, 1)) * duration)
    }

    func togglePlaylist() {
        isPlaylistVisible.toggle()
    }

    func selectPlaylistItem(at index: Int) {
        service?.play(atIndex: index)
    }

    func movePlaylistItem(from source: IndexSet, to destination: Int) {
        guard let from = source.first else { return }
        playlistItems.move(fromOffsets: source, toOffset: destination)
        service?.move(from: from, toOffset: destination)
    }

    func setQueueForPreview(titles: [String], currentIndex: Int = 0) {
        playlistItems = titles.enumerated().map { index, title in
            AudioPlaylistItem(id: "\(index)", title: title, artist: nil, thumbnail: nil)
        }
        currentTrackID = playlistItems.indices.contains(currentIndex) ? playlistItems[currentIndex].id : nil
    }

    func switchPlaybackMode() {
        playbackMode = playbackMode.toggled
    }

    // MARK: - Podcast Mode intents

    func isSelectedSpeed(_ rate: Float) -> Bool {
        rate == playbackSpeed
    }

    func selectPlaybackSpeed(_ rate: Float) {
        service?.setPlaybackSpeed(rate)
    }

    func skipBackward() {
        seek(byOffset: -skipInterval)
    }

    func skipForward() {
        seek(byOffset: skipInterval)
    }

    func startSleepTimer(_ option: SleepTimerOption) {
        if let interval = option.countdownDuration {
            service?.startSleepTimer(after: interval)
        } else {
            service?.startSleepTimerAtEndOfTrack()
        }
    }

    func cancelSleepTimer() {
        service?.cancelSleepTimer()
    }

    // MARK: - Double-tap seek

    func handleSeekGesture(_ direction: SeekDirection) {
        guard duration != nil else { return }
        switch direction {
        case .backward: skipBackward()
        case .forward: skipForward()
        }
        showSeekFeedback(direction)
    }

    /// Seek relative to the current position (negative = backward).
    private func seek(byOffset offset: TimeInterval) {
        seek(toSeconds: currentTime + offset)
    }

    private func seek(toSeconds seconds: TimeInterval) {
        guard let duration else { return }
        let target = max(0, min(seconds, duration))
        currentTime = target
        service?.seek(toSeconds: target)
    }

    private func showSeekFeedback(_ direction: SeekDirection) {
        visibleSeekFeedback = direction
        seekFeedbackTask?.cancel()
        seekFeedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.seekFeedbackDuration))
            guard !Task.isCancelled else { return }
            self?.visibleSeekFeedback = nil
        }
    }
}
