import Combine
import Foundation
import MEGASwiftUI
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

    /// Current track's artwork URL — mirrored from the service state. Exposed
    /// publicly so the View can attach `.task(id: vm.artworkURLString)` and get
    /// cancel-on-change behavior for free, instead of the VM owning a Task.
    @Published private(set) var artworkURLString: String?

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

    /// Drives the center button's play/pause glyph.
    @Published private(set) var isPlaying: Bool = false

    @Published private(set) var isShuffleOn: Bool = false

    @Published private(set) var repeatMode: RepeatMode = .off

    @Published private(set) var playbackMode: PlaybackMode = .music

    /// `true` when the three-dot menu should be hidden — matches the legacy
    /// player which hides `moreButton` for offline playback.
    var isActionsMenuHidden: Bool {
        if case .offlineFiles = currentSource { return true }
        return currentSource == nil
    }

    private let service: (any AudioPlaybackServiceProtocol)?
    private let imageLoader: any ImageLoadingProtocol
    private var cancellables: Set<AnyCancellable> = []

    /// Preview / placeholder init. No service binding; intents are no-ops.
    init(imageLoader: any ImageLoadingProtocol = ImageLoader()) {
        self.service = nil
        self.imageLoader = imageLoader
    }

    /// Production init. VM mirrors the service's `statePublisher` into its
    /// `@Published` fields and forwards all user intents back to the service.
    init(
        service: any AudioPlaybackServiceProtocol,
        imageLoader: any ImageLoadingProtocol = ImageLoader()
    ) {
        self.service = service
        self.imageLoader = imageLoader
        bindService(service)
    }

    private func bindService(_ service: any AudioPlaybackServiceProtocol) {
        service.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.apply(state: state)
            }
            .store(in: &cancellables)
    }

    private func apply(state: AudioPlaybackState?) {
        currentSource = state?.currentSource
        artworkURLString = state?.artworkURLString
    }

    /// Download cover artwork for the current `artworkURLString` and publish
    /// the resulting image + dominant glow color. Driven by the View via
    /// `.task(id: vm.artworkURLString)`, which provides cancel-on-change and
    /// cancel-on-disappear automatically — no stored Task on the VM needed.
    func loadArtwork() async {
        guard let urlString = artworkURLString,
              let url = URL(string: urlString) else {
            artworkImage = nil
            glowColor = nil
            return
        }

        guard let image = await imageLoader.loadImage(from: url) else { return }
        let color = await extractDominantColor(from: image)

        // `.task(id:)` cancels us when the URL changes; defend against assigning
        // stale artwork to the (already-superseded) Published properties.
        guard !Task.isCancelled else { return }
        artworkImage = image
        glowColor = color
    }

    /// `nonisolated async` ensures Core Image work (`CIAreaAverage`) runs on the
    /// cooperative pool rather than the MainActor's executor (per SE-0338,
    /// non-actor-isolated async functions never run on an actor's executor).
    nonisolated private func extractDominantColor(from image: UIImage) async -> Color? {
        guard !Task.isCancelled else { return nil }
        return image.mnz_dominantColor.map(Color.init(uiColor:))
    }

    func dismiss() {
        onDismiss?()
    }

    func didTapMore() {
        guard let currentSource else { return }
        onMoreTap?(currentSource)
    }

    /// Seed `artworkImage` + `glowColor` directly. Normally driven by the
    /// artwork-URL pipeline in `applyArtworkURL`; exposed for tests / preview.
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
        playbackMode: PlaybackMode = .music
    ) {
        self.title = title
        self.artist = artist
        self.currentTime = currentTime
        self.duration = 100 // duration
        self.isPlaying = isPlaying
        self.isShuffleOn = isShuffleOn
        self.repeatMode = repeatMode
        self.playbackMode = playbackMode
    }

    // MARK: - Music Mode intents (engine integration pending)

    func togglePlayPause() {
        isPlaying.toggle()
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
        guard let duration else { return }
        currentTime = max(0, min(fraction, 1)) * duration
    }

    func presentAirPlay() {
    }

    func presentPlaylist() {
    }

    func switchPlaybackMode() {
    }
}
