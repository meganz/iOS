import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI
import UIKit

struct AudioPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    /// Distance the user must drag down before a swipe is treated as a
    /// dismiss intent. Below this, treat as accidental motion.
    private let dismissDragThreshold: CGFloat = 100
    /// Predicted end-position threshold, used so a quick flick dismisses
    /// even when the absolute drag distance is short.
    private let dismissFlickThreshold: CGFloat = 250

    var body: some View {
        ZStack {
            BackgroundLayer()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ArtworkSection(coverImage: vm.artworkImage, glowColor: vm.glowColor, isPlaying: vm.isPlaying)
                    .padding(.top, TokenSpacing._15)

                Spacer(minLength: TokenSpacing._9)

                TrackInfoSection(title: vm.title, artist: vm.artist)
                    .padding(TokenSpacing._5)
                    .frame(height: 74)

                ScrubberSection(
                    currentTime: vm.currentTime,
                    duration: vm.duration,
                    onSeek: { vm.seek(toFraction: $0) }
                )
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .frame(height: TokenSpacing._15)

                Group {
                    switch vm.playbackMode {
                    case .music:
                        MusicModeControlsSection(
                            isPlaying: vm.isPlaying,
                            isShuffleOn: vm.isShuffleOn,
                            repeatMode: vm.repeatMode,
                            onShuffle: vm.toggleShuffle,
                            onSkipPrevious: vm.skipPrevious,
                            onPlayPause: vm.togglePlayPause,
                            onSkipNext: vm.skipNext,
                            onRepeat: vm.cycleRepeat
                        )
                    case .podcast:
                        PodcastModeControlsSection(
                            isPlaying: vm.isPlaying,
                            speed: vm.podcastPlaybackSpeed,
                            isSleepTimerActive: vm.isSleepTimerActive,
                            onSpeed: vm.presentSpeedPicker,
                            onBackward: vm.skipBackward,
                            onPlayPause: vm.togglePlayPause,
                            onForward: vm.skipForward,
                            onSleepTimer: vm.presentSleepTimer
                        )
                    }
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.top, TokenSpacing._3)
                .frame(height: TokenSpacing._17)

                BottomActionsSection(
                    currentMode: vm.playbackMode,
                    isAirPlayActive: vm.isAirPlayActive,
                    onModeToggle: vm.switchPlaybackMode,
                    onPlaylist: vm.presentPlaylist
                )
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._7)
                .frame(height: 96)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    vm.dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.isActionsMenuHidden {
                    Button {
                        vm.didTapMore()
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .simultaneousGesture(swipeDownToDismiss)
        .task(id: vm.artworkData) {
            await vm.loadArtwork()
        }
    }

    /// Dismiss the player on a downward swipe. Uses `simultaneousGesture` so
    /// the scrubber and button taps still receive their touches; the gesture only acts on release with
    /// sufficient vertical drag distance or flick velocity.
    private var swipeDownToDismiss: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dy = value.translation.height
                let predictedDy = value.predictedEndTranslation.height
                // Reject mostly-horizontal motion
                guard abs(value.translation.width) < dy else { return }
                if dy > dismissDragThreshold || predictedDy > dismissFlickThreshold {
                    vm.dismiss()
                }
            }
    }
}

// MARK: - Background

private struct BackgroundLayer: View {

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 73 / 255, green: 9 / 255, blue: 0),
                Color(red: 21 / 255, green: 22 / 255, blue: 22 / 255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Artwork

private struct ArtworkSection: View {
    let coverImage: UIImage?
    let glowColor: Color?
    let isPlaying: Bool

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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPlaying)
    }

    private var coverScale: CGFloat {
        isPlaying ? 1 : coverReducedSize / coverMaxSize
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
            .background(Color.white.opacity(0.05))
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
    let onSeek: (Double) -> Void

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
            Text(formatElapsed(displayTime, duration: duration))
            Spacer()
            Text(formatRemaining(currentTime: displayTime, duration: duration))
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
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

// MARK: - Music Mode Controls

/// Transport controls (shuffle / prev / play-pause / next / repeat)
private struct MusicModeControlsSection: View {
    let isPlaying: Bool
    let isShuffleOn: Bool
    let repeatMode: RepeatMode
    let onShuffle: () -> Void
    let onSkipPrevious: () -> Void
    let onPlayPause: () -> Void
    let onSkipNext: () -> Void
    let onRepeat: () -> Void

    private let secondaryIconSize: CGFloat = 22

    var body: some View {
        HStack {
            iconButton(
                image: MEGAAssets.Image.audioShuffle,
                size: secondaryIconSize,
                isAccented: isShuffleOn,
                action: onShuffle
            )
            .overlay(alignment: .bottom) { activeDot(isVisible: isShuffleOn) }
            .padding(TokenSpacing._5)
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioSkipBack,
                size: TokenSpacing._8,
                isAccented: false,
                action: onSkipPrevious
            )
            Spacer()
            (isPlaying ? MEGAAssets.Image.monoPauseMediumThinSolid : MEGAAssets.Image.monoPlayMediumThinSolid)
                .resizable()
                .scaledToFit()
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: TokenSpacing._15, height: TokenSpacing._15)
                .contentShape(Rectangle())
                .onTapGesture(perform: onPlayPause)
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioSkipForward,
                size: TokenSpacing._8,
                isAccented: false,
                action: onSkipNext
            )
            Spacer()
            iconButton(
                image: repeatMode == .one ? MEGAAssets.Image.audioRepeatOne : MEGAAssets.Image.audioRepeat,
                size: secondaryIconSize,
                isAccented: repeatMode != .off,
                action: onRepeat
            )
            .overlay(alignment: .bottom) { activeDot(isVisible: repeatMode != .off) }
            .padding(TokenSpacing._5)
        }
        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
    }

    private func iconButton(image: Image, size: CGFloat, isAccented: Bool, action: @escaping () -> Void) -> some View {
        image
            .foregroundStyle(isAccented ? TokenColors.Icon.brand.swiftUI : TokenColors.Icon.primary.swiftUI)
            .frame(width: size)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
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
    let isPlaying: Bool
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
            (isPlaying ? MEGAAssets.Image.monoPauseMediumThinSolid : MEGAAssets.Image.monoPlayMediumThinSolid)
                .resizable()
                .scaledToFit()
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: TokenSpacing._15, height: TokenSpacing._15)
                .contentShape(Rectangle())
                .onTapGesture(perform: onPlayPause)
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
    }

    private func iconButton(image: Image, size: CGFloat, isAccented: Bool = false, action: @escaping () -> Void) -> some View {
        image
            .foregroundStyle(isAccented ? TokenColors.Icon.brand.swiftUI : TokenColors.Icon.primary.swiftUI)
            .frame(width: size)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private func activeDot(isVisible: Bool) -> some View {
        Circle()
            .fill(TokenColors.Icon.brand.swiftUI)
            .frame(width: TokenSpacing._2, height: TokenSpacing._2)
            .offset(y: TokenSpacing._3)
            .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - Bottom Actions

private struct BottomActionsSection: View {
    let currentMode: PlaybackMode
    let isAirPlayActive: Bool
    let onModeToggle: () -> Void
    let onPlaylist: () -> Void

    var body: some View {
        HStack {
            AirPlayIconButton(isActive: isAirPlayActive)

            Spacer()

            Button(action: onModeToggle) {
                Text(oppositeModeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .kerning(-0.4)
            }
            .buttonStyle(.mega(type: .secondary))
            .fixedSize()

            Spacer()

            iconButton(image: MEGAAssets.Image.audioPlaylist, action: onPlaylist)
        }
        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
    }

    private func iconButton(image: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            image
                .padding(TokenSpacing._3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            isPlaying: true,
            playbackMode: .music
        )
        return vm
    }())
}

#Preview("Music — Empty / idle") {
    AudioPlayerView(vm: AudioPlayerViewModel())
}

#Preview("Podcast — Playing") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        vm.setControlState(
            title: "Orange (Live)",
            artist: "Arcy Drive",
            currentTime: 80,
            duration: 234,
            isPlaying: true,
            playbackMode: .podcast,
            podcastPlaybackSpeed: 2,
            isSleepTimerActive: true
        )
        return vm
    }())
}
