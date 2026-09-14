import MEGAAssets
import MEGADesignToken
import MEGAInfrastructure
import MEGAL10n
import SwiftUI

/// The video player's audio track picker — a Liquid Glass panel that floats above the timeline
struct AudioTrackMenu: View {
    let selection: AudioTrackSelection
    let onSelect: (AudioTrack) -> Void

    static let width: CGFloat = 241
    static let rowHeight: CGFloat = TokenSpacing._12

    /// Surface tint over the glass — tames Liquid Glass's transparency so the rows stay legible over video.
    private static let surfaceOpacity: CGFloat = 0.67
    /// `TokenSpacing._7` is 24, the same as `TokenRadius.extraLarge`.
    private static let horizontalPadding: CGFloat = TokenSpacing._7

    private static let separatorHeight: CGFloat = 1
    /// Breathing room between the panel's rounded edge and the first and last rows.
    private static let verticalPadding: CGFloat = TokenSpacing._4

    /// The track list shows at most this many rows and scrolls beyond them, so the panel
    /// cannot outgrow the player — MP4 sets no upper bound on a file's audio track count.
    private static let maxVisibleTrackCount = 4

    /// The panel's total height, so callers can position it relative to its anchor.
    static func height(trackCount: Int) -> CGFloat {
        verticalPadding * 2
            + rowHeight * CGFloat(min(trackCount, maxVisibleTrackCount) + 1)
            + separatorHeight
    }

    private var trackListHeight: CGFloat {
        Self.rowHeight * CGFloat(min(selection.tracks.count, Self.maxVisibleTrackCount))
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: TokenRadius.extraLarge) }

    var body: some View {
        panel
            .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var panel: some View {
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
        VStack(spacing: .zero) {
            headerRow
            separator
            trackList
        }
        .padding(.vertical, Self.verticalPadding)
        .frame(width: Self.width)
    }

    /// The header stays pinned; only the tracks scroll.
    private var trackList: some View {
        ScrollView {
            VStack(spacing: .zero) {
                ForEach(selection.tracks) { audioTrack in
                    trackRow(audioTrack)
                }
            }
        }
        .frame(height: trackListHeight)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var separator: some View {
        TokenColors.Border.subtle.swiftUI
            .frame(height: Self.separatorHeight)
            .padding(.horizontal, Self.horizontalPadding)
    }

    private var headerRow: some View {
        row {
            MEGAAssets.Image.monoWaveformMediumThinOutline
                .renderingMode(.template)
                .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            Text(Strings.Localizable.VideoPlayer.AudioTrack.BottomSheet.title)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(TokenColors.Text.onColor.swiftUI)
    }

    private func trackRow(_ audioTrack: AudioTrack) -> some View {
        row {
            // Always laid out and toggled with opacity so checking a row does not shift its title.
            MEGAAssets.Image.check
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: TokenSpacing._7, height: TokenSpacing._7)
                .opacity(audioTrack == selection.selected ? 1 : 0)
            Text(audioTrack.displayName)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .foregroundStyle(TokenColors.Text.onColor.swiftUI)
        .contentShape(Rectangle())
        .onTapGesture { onSelect(audioTrack) }
    }

    private func row(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: TokenSpacing._3) {
            content()
        }
        .frame(height: Self.rowHeight)
        // Matches the corner radius so the first and last rows clear the curve instead of
        // crowding into it.
        .padding(.horizontal, Self.horizontalPadding)
    }
}
