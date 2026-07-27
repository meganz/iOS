import MEGAAssets
import MEGADesignToken
import MEGAFoundation
import MEGAInfrastructure
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI
import UIKit

private enum PodcastMenu {
    case speed
    case sleepOptions
    case turnOff
}

/// Bounds of the podcast controls that anchor a popover menu
private struct PodcastMenuAnchors {
    var speed: Anchor<CGRect>?
    var clock: Anchor<CGRect>?

    init(speed: Anchor<CGRect>? = nil, clock: Anchor<CGRect>? = nil) {
        self.speed = speed
        self.clock = clock
    }
}

private struct PodcastMenuAnchorsKey: PreferenceKey {
    static let defaultValue = PodcastMenuAnchors()
    static func reduce(value: inout PodcastMenuAnchors, nextValue: () -> PodcastMenuAnchors) {
        let next = nextValue()
        if let speed = next.speed { value.speed = speed }
        if let clock = next.clock { value.clock = clock }
    }
}

/// Carries the global-space Y of the scrollable playlist's top up to the view
private struct PlaylistListTopPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct AudioPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    @State private var activeMenu: PodcastMenu?

    var body: some View {
        ZStack {
            BackgroundLayer(isFlipped: vm.isPlaylistVisible)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                mainContent
                    .frame(maxHeight: .infinity)

                ScrubberSection(
                    currentTime: vm.currentTime,
                    duration: vm.duration,
                    loadingState: vm.loadingState,
                    sleepTimerState: vm.sleepTimerState,
                    onSeek: { vm.seek(toFraction: $0) }
                )
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .frame(height: TokenSpacing._15)

                Group {
                    switch vm.playbackMode {
                    case .music:
                        MusicModeControlsSection(
                            loadingState: vm.loadingState,
                            isShuffleOn: vm.isShuffleOn,
                            repeatMode: vm.repeatMode,
                            isSingleTrack: vm.isSingleTrack,
                            isOnLastTrack: vm.isOnLastTrack,
                            onShuffle: vm.toggleShuffle,
                            onSkipPrevious: vm.skipPrevious,
                            onPlayPause: vm.togglePlayPause,
                            onSkipNext: vm.skipNext,
                            onRepeat: vm.cycleRepeat
                        )
                    case .podcast:
                        PodcastModeControlsSection(
                            loadingState: vm.loadingState,
                            speed: vm.playbackSpeed,
                            isSleepTimerActive: vm.isSleepTimerActive,
                            onSpeed: { activeMenu = .speed },
                            onBackward: vm.skipBackward,
                            onPlayPause: vm.togglePlayPause,
                            onForward: vm.skipForward,
                            onSleepTimer: { activeMenu = vm.isSleepTimerActive ? .turnOff : .sleepOptions }
                        )
                    }
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.top, TokenSpacing._3)
                .frame(height: TokenSpacing._17)

                BottomActionsSection(
                    currentMode: vm.playbackMode,
                    isAirPlayActive: vm.isAirPlayActive,
                    loadingState: vm.loadingState,
                    isQueueEnabled: vm.isQueueButtonEnabled && !vm.isSingleTrack,
                    isPlaylistActive: vm.isPlaylistVisible,
                    onModeToggle: vm.switchPlaybackMode,
                    onPlaylist: vm.togglePlaylist
                )
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._7)
                .frame(height: 96)
            }
        }
        .overlayPreferenceValue(PodcastMenuAnchorsKey.self) { anchors in
            podcastMenuOverlay(anchors)
        }
        .overlay(alignment: .leading) {
            SeekFeedbackView(direction: .backward, seconds: Int(vm.skipInterval))
                .opacity(vm.visibleSeekFeedback == .backward ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: vm.visibleSeekFeedback)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .overlay(alignment: .trailing) {
            SeekFeedbackView(direction: .forward, seconds: Int(vm.skipInterval))
                .opacity(vm.visibleSeekFeedback == .forward ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: vm.visibleSeekFeedback)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            playerHeader
        }
        .preferredColorScheme(.dark)
        .task(id: vm.artworkData) {
            await vm.loadArtwork()
        }
        .alert(
            Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.title,
            isPresented: Binding(
                get: { vm.resumePrompt != nil },
                set: { _ in }
            ),
            presenting: vm.resumePrompt
        ) { _ in
            Button(Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.restart) {
                vm.restartPlayback()
            }
            Button(Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.resume) {
                vm.resumePlayback()
            }
        } message: { prompt in
            Text(Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.description(prompt.fileName, prompt.playbackTime.timeString))
        }
    }

    private var seekGestureLayer: some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture(count: 2)
                        .onEnded { value in
                            let direction: SeekDirection = value.location.x < proxy.size.width / 2 ? .backward : .forward
                            vm.handleSeekGesture(direction)
                        }
                )
        }
    }

    private var playerHeader: some View {
        HStack {
            Button {
                vm.dismiss()
            } label: {
                MEGAAssets.Image.monoChevronDownMediumThinOutline
                    .frame(width: TokenSpacing._12, height: TokenSpacing._12)
                    .glassCircleIfAvailable()
                    .contentShape(Rectangle())
            }

            Spacer()

            if !vm.isActionsMenuHidden {
                Button {
                    vm.didTapMore()
                } label: {
                    MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                        .frame(width: TokenSpacing._12, height: TokenSpacing._12)
                        .glassCircleIfAvailable()
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .font(.title3)
        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
    }

    // MARK: - Podcast popover menus
    private var mainContent: some View {
        ZStack {
            VStack(spacing: 0) {
                ArtworkSection(coverImage: vm.artworkImage, glowColor: vm.glowColor, loadingState: vm.loadingState)
                    .frame(maxWidth: .infinity)
                    .overlay { seekGestureLayer }
                    .padding(.top, TokenSpacing._15)
                Spacer(minLength: TokenSpacing._9)
                TrackInfoSection(title: vm.title, artist: vm.artist)
                    .padding(TokenSpacing._5)
                    .frame(height: TokenSpacing._15)
            }
            .opacity(vm.isPlaylistVisible ? 0 : 1)
            .allowsHitTesting(!vm.isPlaylistVisible)

            VStack(spacing: 0) {
                NowPlayingCompactHeader(coverImage: vm.artworkImage, title: vm.title, artist: vm.artist)
                    .padding(.horizontal, TokenSpacing._5)
                    .padding(.vertical, TokenSpacing._3)
                    .frame(height: TokenSpacing._17)
                PlaylistView(
                    sourceName: vm.artist,
                    items: vm.playlistItems,
                    currentTrackID: vm.currentTrackID,
                    onSelect: vm.selectPlaylistItem,
                    onMove: vm.movePlaylistItem,
                    loadMetadata: { await vm.metadata(forID: $0) }
                )
                .frame(maxHeight: .infinity)
                .overlay(alignment: .top) {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: PlaylistListTopPreferenceKey.self,
                            value: proxy.frame(in: .global).minY
                        )
                    }
                    .frame(height: 0)
                }
                .onPreferenceChange(PlaylistListTopPreferenceKey.self) { [vm] value in
                    Task { @MainActor in vm.updatePlaylistListTopY(value) }
                }
            }
            .padding(.top, TokenSpacing._3)
            .opacity(vm.isPlaylistVisible ? 1 : 0)
            .allowsHitTesting(vm.isPlaylistVisible)
        }
    }

    @ViewBuilder
    private func podcastMenuOverlay(_ anchors: PodcastMenuAnchors) -> some View {
        if let activeMenu {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { self.activeMenu = nil }

                    positionedMenu(activeMenu, anchors: anchors, proxy: proxy)
                }
            }
        }
    }

    @ViewBuilder
    private func positionedMenu(_ menu: PodcastMenu, anchors: PodcastMenuAnchors, proxy: GeometryProxy) -> some View {
        switch menu {
        case .speed:
            if let anchor = anchors.speed {
                let rect = proxy[anchor]
                speedMenu.offset(
                    x: rect.maxX + TokenSpacing._3,
                    y: rect.maxY + TokenSpacing._3 - GlassMenu.height(rowCount: vm.playbackSpeedOptions.count)
                )
            }
        case .sleepOptions:
            if let anchor = anchors.clock {
                let rect = proxy[anchor]
                sleepOptionsMenu.offset(
                    x: proxy.size.width - TokenSpacing._4 - GlassMenu.sleepWidth,
                    y: rect.maxY - TokenSpacing._3 - GlassMenu.height(rowCount: SleepTimerOption.allCases.count + 1)
                )
            }
        case .turnOff:
            if let anchor = anchors.clock {
                let rect = proxy[anchor]
                turnOffMenu.offset(
                    x: proxy.size.width - TokenSpacing._5 - GlassMenu.turnOffWidth,
                    y: rect.maxY + TokenSpacing._3 - GlassMenu.height(rowCount: 1)
                )
            }
        }
    }

    private var speedMenu: some View {
        GlassMenu(
            width: GlassMenu.defaultWidth,
            rows: vm.playbackSpeedOptions.map { value in
                GlassMenu.Row(
                    title: "\(String(format: "%g", value))×",
                    isChecked: vm.isSelectedSpeed(value),
                    action: {
                        vm.selectPlaybackSpeed(value)
                        activeMenu = nil
                    }
                )
            }
        )
    }

    private var sleepOptionsMenu: some View {
        var rows = [GlassMenu.Row(title: Strings.Localizable.Media.Audio.Player.SleepTimer.title, isHeader: true)]
        rows += SleepTimerOption.allCases.map { option in
            GlassMenu.Row(
                title: sleepOptionTitle(option),
                action: {
                    vm.startSleepTimer(option)
                    activeMenu = nil
                }
            )
        }
        return GlassMenu(width: GlassMenu.sleepWidth, rows: rows)
    }

    private var turnOffMenu: some View {
        GlassMenu(
            width: GlassMenu.turnOffWidth,
            rows: [GlassMenu.Row(title: Strings.Localizable.Media.Audio.Player.SleepTimer.Option.turnOff, action: {
                vm.cancelSleepTimer()
                activeMenu = nil
            })]
        )
    }

    private func sleepOptionTitle(_ option: SleepTimerOption) -> String {
        switch option {
        case .fiveMinutes: Strings.Localizable.Media.Audio.Player.SleepTimer.Option.minutes(5)
        case .fifteenMinutes: Strings.Localizable.Media.Audio.Player.SleepTimer.Option.minutes(15)
        case .thirtyMinutes: Strings.Localizable.Media.Audio.Player.SleepTimer.Option.minutes(30)
        case .sixtyMinutes: Strings.Localizable.Media.Audio.Player.SleepTimer.Option.minutes(60)
        case .endOfTrack: Strings.Localizable.Media.Audio.Player.SleepTimer.Option.endOfTrack
        }
    }
}

// MARK: - Background

private extension View {
    @ViewBuilder
    func glassCircleIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: .circle)
        } else {
            self
        }
    }
}

private struct BackgroundLayer: View {
    var isFlipped: Bool = false

    private let warmTint = Color(red: 0.36, green: 0.07, blue: 0.05)

    var body: some View {
        LinearGradient(
            colors: [warmTint, TokenColors.Background.page.swiftUI],
            startPoint: isFlipped ? .bottomLeading : .topLeading,
            endPoint: isFlipped ? .topTrailing : .bottomTrailing
        )
    }
}

// MARK: - Artwork

private struct ArtworkSection: View {
    let coverImage: UIImage?
    let glowColor: Color?
    let loadingState: PlayerLoadingState

    private let coverMaxSize = 322.0
    private let coverReducedSize = 290.0
    private let placeholderWidth = 183.0
    private let placeholderHeight = 206.0
    private let glowHeight = 315.0
    private let glowBlurRadius = 125.0

    var body: some View {
        ZStack {
            glow
            cover
        }
        .scaleEffect(coverScale, anchor: .center)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: loadingState)
    }

    private var coverScale: CGFloat {
        switch loadingState {
        case .playing: 1
        case .paused, .loading, .ready: coverReducedSize / coverMaxSize
        }
    }

    /// color halo behind the artwork . The blur extends rendered pixels ~125pt beyond
    /// the rectangle bounds, so the color halo bleeds out from behind the artwork on all sides.
    /// The `EllipticalGradient` with `center: (0.5, 0.08)` anchors the gradient
    /// near the top, biasing the visible halo upward
    @ViewBuilder
    private var glow: some View {
        if let glowColor {
            EllipticalGradient(
                stops: [
                    .init(color: glowColor, location: 0.00),
                    .init(color: glowColor, location: 1.00)
                ],
                center: UnitPoint(x: 0.5, y: 0.08)
            )
            .frame(width: coverMaxSize, height: glowHeight)
            .cornerRadius(TokenSpacing._5)
            .blur(radius: glowBlurRadius)
        }
    }

    private var cover: some View {
        coverContent
            .frame(width: coverMaxSize, height: coverMaxSize)
            .background(TokenColors.Text.primary.swiftUI.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.large))
    }

    @ViewBuilder
    private var coverContent: some View {
        if let coverImage {
            Image(uiImage: coverImage)
                .resizable()
                .scaledToFill()
        } else {
            coverPlaceholder
        }
    }

    private var coverPlaceholder: some View {
        MEGAAssets.Image.audioIcon
            .resizable()
            .scaledToFit()
            .frame(width: placeholderWidth, height: placeholderHeight)
    }
}

// MARK: - Seek Feedback

private struct SeekFeedbackView: View {
    let direction: SeekDirection
    let seconds: Int

    private let chevronSize: CGFloat = TokenSpacing._7
    private let arcWidth: CGFloat = 157
    private let arcColor = TokenColors.Background.surfaceTransparent.swiftUI

    var body: some View {
        let alignment: Alignment = direction == .backward ? .leading : .trailing
        ZStack(alignment: alignment) {
            arc

            label
                .padding(direction == .backward ? .leading : .trailing, TokenSpacing._7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .clipped()
    }

    private var arc: some View {
        GeometryReader { proxy in
            let halfHeight = proxy.size.height / 2
            let radius = (arcWidth * arcWidth + halfHeight * halfHeight) / (2 * arcWidth)
            let centerX = direction == .backward
                ? arcWidth - radius
                : proxy.size.width - (arcWidth - radius)
            Circle()
                .fill(arcColor)
                .frame(width: radius * 2, height: radius * 2)
                .position(x: centerX, y: halfHeight)
        }
    }

    private var label: some View {
        HStack(spacing: TokenSpacing._5) {
            if direction == .backward {
                chevron
                text
            } else {
                text
                chevron
            }
        }
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }

    private var chevron: some View {
        (direction == .backward
            ? MEGAAssets.Image.monoChevronsLeftMediumThinOutline
            : MEGAAssets.Image.monoChevronsRightMediumThinOutline)
            .resizable()
            .scaledToFit()
            .frame(width: chevronSize, height: chevronSize)
    }

    private var text: some View {
        Text(direction == .backward ? "-\(seconds)" : "+\(seconds)")
            .font(.body)
    }
}

// MARK: - Track Info

private struct TrackInfoSection: View {
    let title: String?
    let artist: String?

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._1) {
            Text(title ?? "")
                .font(.title3.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(1)

            Text(artist ?? "")
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(title == nil && artist == nil ? 0 : 1)
    }
}

// MARK: - Scrubber

private struct ScrubberSection: View {
    let currentTime: TimeInterval
    let duration: TimeInterval?
    let loadingState: PlayerLoadingState
    let sleepTimerState: SleepTimerState
    let onSeek: (Double) -> Void

    private static let timePlaceholder = "--:--"

    @State private var dragFraction: Double?

    var body: some View {
        VStack(spacing: TokenSpacing._2) {
            MEGASliderView(
                value: Binding(
                    get: { displayFraction },
                    set: { dragFraction = $0 }
                ),
                isEnabled: duration != nil,
                tapToSeekEnabled: true,
                minimumTrackColor: TokenColors.Icon.brand.swiftUI,
                thumbColor: TokenColors.Icon.brand.swiftUI,
                onEditingChanged: { editing in
                    if !editing, let fraction = dragFraction {
                        onSeek(fraction)
                        dragFraction = nil
                    }
                }
            )
            .frame(height: TokenSpacing._8)

            timeLabels
        }
    }

    private var timeLabels: some View {
        HStack {
            Text(elapsedLabel)
            Spacer()
            if sleepTimerState.isActive {
                sleepTimerLabel
                Spacer()
            }
            Text(remainingLabel)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }

    private var elapsedLabel: String {
        loadingState == .loading ? Self.timePlaceholder : formatElapsed(displayTime, duration: duration)
    }

    private var remainingLabel: String {
        loadingState == .loading ? Self.timePlaceholder : formatRemaining(currentTime: displayTime, duration: duration)
    }

    @ViewBuilder
    private var sleepTimerLabel: some View {
        switch sleepTimerState {
        case .inactive:
            EmptyView()
        case .countdown(let deadline):
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Strings.Localizable.Media.Audio.Player.SleepTimer.remaining(
                    formatSleepRemaining(deadline.timeIntervalSince(context.date))
                ))
            }
        case .endOfTrack:
            Text(Strings.Localizable.Media.Audio.Player.SleepTimer.remaining(formatSleepRemaining(endOfTrackRemaining)))
        }
    }

    /// Seconds left in the current track, for the end-of-track sleep timer label.
    private var endOfTrackRemaining: TimeInterval {
        guard let duration else { return 0 }
        return max(0, duration - currentTime)
    }

    private func formatSleepRemaining(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }

    private var displayFraction: Double {
        if let dragFraction { return dragFraction }
        guard let duration, duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    private var displayTime: TimeInterval {
        if let dragFraction, let duration { return dragFraction * duration }
        return currentTime
    }

    private func formatElapsed(_ seconds: TimeInterval, duration: TimeInterval?) -> String {
        guard duration != nil, seconds.isFinite, !seconds.isNaN else { return "" }
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func formatRemaining(currentTime: TimeInterval, duration: TimeInterval?) -> String {
        guard let duration, duration.isFinite, !duration.isNaN else { return "" }
        let remaining = max(0, duration - currentTime)
        let total = Int(remaining.rounded())
        return String(format: "-%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Loading Helpers

private extension View {
    func controlDisabled(_ isDisabled: Bool) -> some View {
        self
            .allowsHitTesting(!isDisabled)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.3 : 1)
    }

    func disabledWhileLoading(_ state: PlayerLoadingState) -> some View {
        controlDisabled(state == .loading)
    }
}

// MARK: - Center Control

private struct CenterControlView: View {
    let loadingState: PlayerLoadingState
    let onPlayPause: () -> Void

    var body: some View {
        Group {
            switch loadingState {
            case .loading, .ready:
                LoaderThrobber()
                    .padding(TokenSpacing._3)
            case .playing, .paused:
                (loadingState == .playing ? MEGAAssets.Image.monoPauseMediumThinSolid : MEGAAssets.Image.monoPlayMediumThinSolid)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onPlayPause)
            }
        }
        .frame(width: TokenSpacing._15, height: TokenSpacing._15)
    }
}

// MARK: - Music Mode Controls

/// Transport controls (shuffle / prev / play-pause / next / repeat)
private struct MusicModeControlsSection: View {
    let loadingState: PlayerLoadingState
    let isShuffleOn: Bool
    let repeatMode: RepeatMode
    let isSingleTrack: Bool
    let isOnLastTrack: Bool
    let onShuffle: () -> Void
    let onSkipPrevious: () -> Void
    let onPlayPause: () -> Void
    let onSkipNext: () -> Void
    let onRepeat: () -> Void

    private let secondaryIconSize: CGFloat = 22

    private var isShuffleDisabled: Bool {
        isSingleTrack || (isOnLastTrack && !isShuffleOn)
    }

    var body: some View {
        HStack {
            iconButton(
                image: MEGAAssets.Image.audioShuffle,
                size: secondaryIconSize,
                isAccented: isShuffleOn,
                isDisabled: isShuffleDisabled,
                showsActiveDot: isShuffleOn,
                action: onShuffle
            )
            .padding(TokenSpacing._5)
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioSkipBack,
                size: TokenSpacing._8,
                isAccented: false,
                action: onSkipPrevious
            )
            Spacer()
            CenterControlView(loadingState: loadingState, onPlayPause: onPlayPause)
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioSkipForward,
                size: TokenSpacing._8,
                isAccented: false,
                isDisabled: isSingleTrack,
                action: onSkipNext
            )
            Spacer()
            iconButton(
                image: repeatMode == .one ? MEGAAssets.Image.audioRepeatOne : MEGAAssets.Image.audioRepeat,
                size: secondaryIconSize,
                isAccented: repeatMode != .off,
                showsActiveDot: repeatMode != .off,
                action: onRepeat
            )
            .padding(TokenSpacing._5)
        }
        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
    }


    private func iconButton(image: Image, size: CGFloat, isAccented: Bool, isDisabled: Bool = false, showsActiveDot: Bool = false, action: @escaping () -> Void) -> some View {
        image
            .foregroundStyle(isAccented ? TokenColors.Icon.brand.swiftUI : TokenColors.Icon.primary.swiftUI)
            .frame(width: size)
            .overlay(alignment: .bottom) { activeDot(isVisible: showsActiveDot) }
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .controlDisabled(loadingState == .loading || isDisabled)
    }

    private func activeDot(isVisible: Bool) -> some View {
        Circle()
            .fill(TokenColors.Icon.brand.swiftUI)
            .frame(width: TokenSpacing._2, height: TokenSpacing._2)
            .offset(y: TokenSpacing._3)
            .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - Podcast Mode Controls
private struct PodcastModeControlsSection: View {
    let loadingState: PlayerLoadingState
    let speed: Float
    let isSleepTimerActive: Bool
    let onSpeed: () -> Void
    let onBackward: () -> Void
    let onPlayPause: () -> Void
    let onForward: () -> Void
    let onSleepTimer: () -> Void

    private let secondaryIconSize: CGFloat = 22

    var body: some View {
        HStack {
            speedButton
                .overlay(alignment: .bottom) { activeDot(isVisible: isSpeedActive) }
                .padding(TokenSpacing._5)
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioBackward15,
                size: TokenSpacing._8,
                action: onBackward
            )
            Spacer()
            CenterControlView(loadingState: loadingState, onPlayPause: onPlayPause)
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioForward15,
                size: TokenSpacing._8,
                action: onForward
            )
            Spacer()
            iconButton(
                image: isSleepTimerActive ? MEGAAssets.Image.audioClockStop : MEGAAssets.Image.audioClock,
                size: secondaryIconSize,
                isAccented: isSleepTimerActive,
                action: onSleepTimer
            )
            .anchorPreference(key: PodcastMenuAnchorsKey.self, value: .bounds) { PodcastMenuAnchors(clock: $0) }
            .overlay(alignment: .bottom) { activeDot(isVisible: isSleepTimerActive) }
            .padding(TokenSpacing._5)
        }
        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
    }

    private var isSpeedActive: Bool {
        speed != 1
    }

    private var speedLabel: String {
        "\(String(format: "%g", speed))×"
    }

    private var speedButton: some View {
        Text(speedLabel)
            .font(.headline.weight(.medium))
            .foregroundStyle(isSpeedActive ? TokenColors.Text.brand.swiftUI : TokenColors.Text.primary.swiftUI)
            .fixedSize()
            .frame(width: secondaryIconSize, height: secondaryIconSize)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSpeed)
            .anchorPreference(key: PodcastMenuAnchorsKey.self, value: .bounds) { PodcastMenuAnchors(speed: $0) }
            .disabledWhileLoading(loadingState)
    }

    private func iconButton(image: Image, size: CGFloat, isAccented: Bool = false, action: @escaping () -> Void) -> some View {
        image
            .foregroundStyle(isAccented ? TokenColors.Icon.brand.swiftUI : TokenColors.Icon.primary.swiftUI)
            .frame(width: size)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .disabledWhileLoading(loadingState)
    }

    private func activeDot(isVisible: Bool) -> some View {
        Circle()
            .fill(TokenColors.Icon.brand.swiftUI)
            .frame(width: TokenSpacing._2, height: TokenSpacing._2)
            .offset(y: TokenSpacing._3)
            .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - Glass Menu
private struct GlassMenu: View {
    struct Row: Identifiable {
        var id: String { title }
        let title: String
        let isChecked: Bool
        let isHeader: Bool
        let action: (() -> Void)?

        init(title: String, isChecked: Bool = false, isHeader: Bool = false, action: (() -> Void)? = nil) {
            self.title = title
            self.isChecked = isChecked
            self.isHeader = isHeader
            self.action = action
        }
    }

    let width: CGFloat
    let rows: [Row]

    static let defaultWidth: CGFloat = 160
    static let sleepWidth: CGFloat = 204
    static let turnOffWidth: CGFloat = 169
    static let rowContentHeight: CGFloat = TokenSpacing._6
    static let rowSpacing: CGFloat = TokenSpacing._4
    static func height(rowCount: Int) -> CGFloat {
        rowContentHeight * CGFloat(rowCount) + rowSpacing * CGFloat(rowCount + 1)
    }

    /// Surface tint over the glass — tames Liquid Glass's transparency so the rows stay legible over a busy background.
    private static let surfaceOpacity: CGFloat = 0.67
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: TokenRadius.extraLarge) }

    var body: some View {
        if #available(iOS 26.0, *), !ProcessInfo.isRunningIOS26_0Beta {
            content
                .glassEffect(
                    .regular.tint(TokenColors.Background.surface1.swiftUI.opacity(Self.surfaceOpacity)),
                    in: shape
                )
        } else {
            content
                .background(legacyBackground)
        }
    }

    private var legacyBackground: some View {
        ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(TokenColors.Background.surface1.swiftUI.opacity(Self.surfaceOpacity))
        }
    }

    private var content: some View {
        VStack(spacing: Self.rowSpacing) {
            ForEach(rows) { row in
                rowView(row)
            }
        }
        .padding(.vertical, Self.rowSpacing)
        .frame(width: width)
    }

    private func rowView(_ row: Row) -> some View {
        HStack(spacing: TokenSpacing._1) {
            MEGAAssets.Image.check
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: TokenSpacing._4, height: TokenSpacing._4)
                .opacity(row.isChecked ? 1 : 0)
            Text(row.title)
                .font(.caption2.weight(.medium))
            Spacer(minLength: 0)
        }
        .foregroundStyle(row.isHeader ? TokenColors.Text.secondary.swiftUI : TokenColors.Text.onColor.swiftUI)
        .frame(height: Self.rowContentHeight)
        .padding(.horizontal, TokenSpacing._3)
        .contentShape(Rectangle())
        .onTapGesture { row.action?() }
    }
}

// MARK: - Bottom Actions

private struct BottomActionsSection: View {
    let currentMode: PlaybackMode
    let isAirPlayActive: Bool
    let loadingState: PlayerLoadingState
    let isQueueEnabled: Bool
    let isPlaylistActive: Bool
    let onModeToggle: () -> Void
    let onPlaylist: () -> Void

    var body: some View {
        HStack {
            AirPlayIconButton(isActive: isAirPlayActive)
                .disabledWhileLoading(loadingState)

            Spacer()

            Button(action: onModeToggle) {
                Text(oppositeModeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .kerning(-0.4)
            }
            .buttonStyle(.mega(type: .secondary))
            .fixedSize()

            Spacer()

            Button(action: onPlaylist) {
                MEGAAssets.Image.audioPlaylist
                    .padding(.horizontal, TokenSpacing._5)
                    .padding(.vertical, TokenSpacing._4)
                    .background {
                        RoundedRectangle(cornerRadius: TokenRadius.medium)
                            .fill(TokenColors.Button.secondary.swiftUI)
                            .opacity(isPlaylistActive ? 1 : 0)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled((loadingState == .loading) || !isQueueEnabled)
        }
        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
    }

    private var oppositeModeLabel: String {
        switch currentMode {
        case .music: Strings.Localizable.Media.Audio.Player.podcastMode
        case .podcast: Strings.Localizable.Media.Audio.Player.musicMode
        }
    }
}

// MARK: - AirPlay Button

private struct AirPlayIconButton: View {
    let isActive: Bool

    var body: some View {
        MEGAAssets.Image.audioAirplay
            .foregroundStyle(
                isActive
                    ? TokenColors.Icon.brand.swiftUI
                    : TokenColors.Icon.primary.swiftUI
            )
            .padding(.vertical, TokenSpacing._4)
            .padding(.horizontal, TokenSpacing._5)
            .overlay {
                AirPlayButton()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
    }
}

// MARK: - Preview

#Preview("Music — Playing") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        vm.setControlState(
            title: "Orange (Live)",
            artist: "Arcy Drive",
            currentTime: 80,
            duration: 234,
            loadingState: .playing,
            playbackMode: .music
        )
        return vm
    }())
}

#Preview("State 1 — Loading") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        vm.setControlState(
            title: "Pioneer To The Falls (Live)",
            artist: "Interpol",
            loadingState: .loading,
            playbackMode: .music
        )
        return vm
    }())
}

#Preview("State 2 — Ready") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        vm.setControlState(
            title: "Pioneer To The Falls (Live)",
            artist: "Interpol",
            loadingState: .ready,
            playbackMode: .music
        )
        vm.setArtwork(image: MEGAAssets.UIImage.audioIcon, glowColor: nil)
        return vm
    }())
}

#Preview("Music — Empty / idle") {
    AudioPlayerView(vm: AudioPlayerViewModel())
}

#Preview("Music — Playlist open") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        vm.setControlState(
            title: "Orange (Live)",
            artist: "Arcy Drive",
            currentTime: 80,
            duration: 234,
            loadingState: .playing,
            playbackMode: .music
        )
        vm.setQueueForPreview(
            titles: ["Orange (Live)", "Superbloomer (Live)", "Liquor Lips (Live)", "Dessert song (Live)"]
        )
        vm.togglePlaylist()
        return vm
    }())
}

#Preview("Podcast — Playing") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        vm.setControlState(
            title: "Orange (Live)",
            artist: "Arcy Drive",
            currentTime: 80,
            duration: 234,
            loadingState: .playing,
            playbackMode: .podcast,
            playbackSpeed: 2,
            sleepTimerState: .countdown(deadline: Date(timeIntervalSinceNow: 299))
        )
        return vm
    }())
}
