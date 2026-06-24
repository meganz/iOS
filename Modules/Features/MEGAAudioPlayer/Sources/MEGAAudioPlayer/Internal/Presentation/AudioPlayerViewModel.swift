import Combine
import Foundation
import SwiftUI
import UIKit

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

    /// Drives the center button's play/pause glyph.
    @Published private(set) var isPlaying: Bool = false

    @Published private(set) var isAirPlayActive: Bool = false

    // MARK: - Music Mode state

    @Published private(set) var isShuffleOn: Bool = false

    @Published private(set) var repeatMode: RepeatMode = .off

    // MARK: - Podcast Mode state

    /// Available podcast playback speeds, in display order.
    let playbackSpeedOptions: [Float] = [2, 1.5, 1, 0.5]

    @Published private(set) var playbackSpeed: Float = 1

    @Published private(set) var isSleepTimerActive: Bool = false

    /// `true` when the three-dot menu should be hidden — matches the legacy
    /// player which hides `moreButton` for offline playback.
    var isActionsMenuHidden: Bool {
        if case .offlineFiles = currentSource { return true }
        return currentSource == nil
    }

    private let service: (any AudioPlaybackServiceProtocol)?
    private var cancellables: Set<AnyCancellable> = []

    /// Preview / placeholder init. No service binding; intents are no-ops.
    init() {
        self.service = nil
    }

    /// Production init. VM mirrors the service's state publishers into its
    /// `@Published` fields and forwards all user intents back to the service.
    init(service: any AudioPlaybackServiceProtocol) {
        self.service = service
        bindService(service)
    }

    private func bindService(_ service: any AudioPlaybackServiceProtocol) {
        service.currentSourcePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currentSource = $0 }
            .store(in: &cancellables)

        service.titlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.title = $0 }
            .store(in: &cancellables)

        service.artistPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.artist = $0 }
            .store(in: &cancellables)

        service.artworkDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.artworkData = $0 }
            .store(in: &cancellables)

        service.currentTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currentTime = $0 }
            .store(in: &cancellables)

        service.durationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.duration = $0 }
            .store(in: &cancellables)

        service.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = status == .playing || status == .buffering
            }
            .store(in: &cancellables)

        service.isAirPlayActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAirPlayActive = $0 }
            .store(in: &cancellables)
        
        service.playbackSpeedPublisher
            .sink { [weak self] in self?.playbackSpeed = $0 }
            .store(in: &cancellables)
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
        isPlaying: Bool = false,
        isShuffleOn: Bool = false,
        repeatMode: RepeatMode = .off,
        playbackMode: PlaybackMode = .music,
        playbackSpeed: Float = 1,
        isSleepTimerActive: Bool = false,
        isAirPlayActive: Bool = false
    ) {
        self.title = title
        self.artist = artist
        self.currentTime = currentTime
        self.duration = duration
        self.isPlaying = isPlaying
        self.isShuffleOn = isShuffleOn
        self.repeatMode = repeatMode
        self.playbackMode = playbackMode
        self.playbackSpeed = playbackSpeed
        self.isSleepTimerActive = isSleepTimerActive
        self.isAirPlayActive = isAirPlayActive
    }

    // MARK: - Music Mode intents

    func togglePlayPause() {
        service?.togglePlayPause()
    }

    func skipPrevious() {
    }

    func skipNext() {
    }

    func toggleShuffle() {
        isShuffleOn.toggle()
    }

    func cycleRepeat() {
        repeatMode = repeatMode.next
    }

    func seek(toFraction fraction: Double) {
        if let duration {
            currentTime = max(0, min(fraction, 1)) * duration
        }
        service?.seek(toFraction: fraction)
    }

    func presentPlaylist() {
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

    /// Seek backward by the podcast skip interval (15s). Stub until wired to the engine.
    func skipBackward() {
    }

    /// Seek forward by the podcast skip interval (15s). Stub until wired to the engine.
    func skipForward() {
    }

    func presentSleepTimer() {
    }
}
