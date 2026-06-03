import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI
import UIKit

private extension Color {
    static let audioPlayerAccent = Color(red: 0.95, green: 0.20, blue: 0.20)
}

struct AudioPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    var body: some View {
        ZStack {
            BackgroundLayer()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ArtworkSection(coverImage: vm.artworkImage, glowColor: vm.glowColor)
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
                        // PodcastModeControlsSection lands in a follow-up ticket.
                        EmptyView()
                    }
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.top, TokenSpacing._3)
                .frame(height: TokenSpacing._17)

                BottomActionsSection(
                    currentMode: vm.playbackMode,
                    onAirPlay: vm.presentAirPlay,
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
        .task(id: vm.artworkURLString) {
            await vm.loadArtwork()
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

    private let artworkSize = 322.0
    private let placeholderWidth = 183.0
    private let placeholderHeight = 206.0
    private let glowHeight = 315.0
    private let glowBlurRadius = 125.0

    var body: some View {
        ZStack {
            glow
            cover
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
            .frame(width: artworkSize, height: glowHeight)
            .cornerRadius(TokenSpacing._5)
            .blur(radius: glowBlurRadius)
        }
    }

    private var cover: some View {
        coverContent
            .frame(width: artworkSize, height: artworkSize)
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
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(artist ?? "")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
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
                minimumTrackColor: .audioPlayerAccent,
                thumbColor: .audioPlayerAccent,
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
                .foregroundStyle(.white.opacity(0.6))
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.white)
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
    private let playPauseIconSize: CGFloat = 44

    var body: some View {
        HStack {
            iconButton(
                image: MEGAAssets.Image.audioShuffle,
                size: secondaryIconSize,
                isAccented: isShuffleOn,
                action: onShuffle
            )
            .overlay(alignment: .bottom) { activeDot(isVisible: isShuffleOn) }
            Spacer()
            iconButton(
                image: MEGAAssets.Image.audioSkipBack,
                size: TokenSpacing._8,
                isAccented: false,
                action: onSkipPrevious
            )
            Spacer()
            iconButton(
                image: Image(systemName: isPlaying ? "pause.fill" : "play.fill"),
                size: playPauseIconSize,
                isAccented: false,
                action: onPlayPause
            )
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
        }
        .foregroundStyle(.white)
    }

    private func iconButton(image: Image, size: CGFloat, isAccented: Bool, action: @escaping () -> Void) -> some View {
        image
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(isAccented ? Color.audioPlayerAccent : Color.white)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private func activeDot(isVisible: Bool) -> some View {
        Circle()
            .fill(Color.audioPlayerAccent)
            .frame(width: TokenSpacing._2, height: TokenSpacing._2)
            .offset(y: TokenSpacing._3)
            .opacity(isVisible ? 1 : 0)
    }
}

// MARK: - Bottom Actions

private struct BottomActionsSection: View {
    let currentMode: PlaybackMode
    let onAirPlay: () -> Void
    let onModeToggle: () -> Void
    let onPlaylist: () -> Void

    var body: some View {
        HStack {
            iconButton(image: MEGAAssets.Image.audioAirplay, action: onAirPlay)

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
        .foregroundStyle(.white)
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
