import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

// MARK: - Playlist

struct PlaylistView: View {
    let sourceName: String?
    let items: [AudioPlaylistItem]
    let currentTrackID: String?
    let isVisible: Bool
    let onSelect: (Int) -> Void
    let onMove: (IndexSet, Int) -> Void
    /// Lazily resolves a row's metadata by track id (from the shared cache).
    let loadMetadata: (String) async -> AudioMetadata?

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, row in
                        let isCurrent = row.id == currentTrackID
                        PlaylistRow(item: row, isCurrent: isCurrent, loadMetadata: loadMetadata)
                            .padding(.horizontal, TokenSpacing._5)
                            .contentShape(Rectangle())
                            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: TokenRadius.small))
                            .onTapGesture { onSelect(index) }
                            .listRowSeparator(.hidden)
                            .listRowBackground(isCurrent ? TokenColors.Button.secondary.swiftUI : Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                    .onMove(perform: onMove)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                // Opening the playlist parks the playing track at the top of the visible
                // area. The layer swap is instant (no fade), so this must be un-animated
                // too — the row is already in place the moment the list is shown. Near the
                // end of the queue there are too few rows left to scroll past, so the
                // track settles as high as it can go.
                .onChange(of: isVisible, initial: true) { _, visible in
                    guard visible else { return }
                    scrollToCurrentTrack(proxy, anchor: .top, animated: false)
                }
                // Skipping tracks keeps the highlighted row on screen. A nil anchor
                // scrolls the minimum needed, so a row that is already visible stays put.
                // Pointless while hidden — opening re-anchors to .top regardless.
                .onChange(of: currentTrackID) { _, _ in
                    guard isVisible else { return }
                    scrollToCurrentTrack(proxy, anchor: nil, animated: true)
                }
                // The playing row can also move without changing identity: switching
                // shuffle off rebuilds the queue in its original order and re-seats the
                // track at whatever index it held there, leaving `currentTrackID` equal.
                // Watching the position catches that; the nil anchor keeps it silent when
                // the row is already on screen, including after a drag-to-reorder.
                .onChange(of: currentTrackIndex) { _, _ in
                    guard isVisible else { return }
                    scrollToCurrentTrack(proxy, anchor: nil, animated: true)
                }
            }
        }
    }

    /// Where the playing track currently sits in the list, or `nil` if it is not in it.
    private var currentTrackIndex: Int? {
        currentTrackID.flatMap { id in items.firstIndex { $0.id == id } }
    }

    /// `anchor` is passed straight to `scrollTo`: `nil` scrolls the minimum needed to make
    /// the row wholly visible (a no-op when it already is), a unit point re-seats it there.
    private func scrollToCurrentTrack(_ proxy: ScrollViewProxy, anchor: UnitPoint?, animated: Bool) {
        // The queue and the current track arrive from the same publisher, but a row
        // that is not on screen yet has no scroll target — skip rather than no-op loudly.
        guard let currentTrackID, items.contains(where: { $0.id == currentTrackID }) else { return }

        if animated {
            withAnimation { proxy.scrollTo(currentTrackID, anchor: anchor) }
        } else {
            proxy.scrollTo(currentTrackID, anchor: anchor)
        }
    }

    @ViewBuilder
    private var header: some View {
        Text(headerText(sourceName: sourceName ?? ""))
            .font(.subheadline)
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headerText(sourceName: String) -> AttributedString {
        let sentinel = "\u{1}"
        var string = AttributedString(Strings.Localizable.Media.Audio.Player.Playlist.playingFrom(sentinel))
        string.foregroundColor = TokenColors.Text.secondary.swiftUI
        if let range = string.range(of: sentinel) {
            var name = AttributedString(sourceName)
            name.foregroundColor = TokenColors.Text.primary.swiftUI
            string.replaceSubrange(range, with: name)
        }
        return string
    }
}

// MARK: - Row

private struct PlaylistRow: View {
    let item: AudioPlaylistItem
    let isCurrent: Bool
    let loadMetadata: (String) async -> AudioMetadata?

    @State private var metadata: AudioMetadata?

    private let thumbnailSize: CGFloat = TokenSpacing._11

    private var displayTitle: String {
        if let title = metadata?.title, !title.isEmpty { return title }
        return item.title
    }

    private var artist: String? { metadata?.artist }

    private var artwork: UIImage? {
        metadata?.artworkData.flatMap(UIImage.init(data:))
    }

    var body: some View {
        HStack(spacing: TokenSpacing._2) {
            thumbnail

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                HStack(spacing: TokenSpacing._1) {
                    if isCurrent {
                        MEGAAssets.Image.monoWaveformSmallThinOutline
                            .resizable()
                            .scaledToFit()
                            .frame(width: TokenSpacing._5, height: TokenSpacing._5)
                    }
                    Text(displayTitle)
                        .font(.body)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .lineLimit(1)
                }

                Text(artist ?? "")
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
                    .opacity(artist == nil ? 0 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MEGAAssets.Image.monoQueueLineMediumThinOutline
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .frame(width: thumbnailSize, height: thumbnailSize)
        }
        .frame(height: 60)
        .task(id: item.id) {
            metadata = await loadMetadata(item.id)
        }
    }

    private var thumbnail: some View {
        Group {
            if let artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                MEGAAssets.Image.audioIcon
                    .resizable()
                    .scaledToFit()
                    .padding(TokenSpacing._2)
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .background(TokenColors.Text.primary.swiftUI.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
    }
}

// MARK: - Compact Now Playing Header

struct NowPlayingCompactHeader: View {
    let coverImage: UIImage?
    let title: String?
    let artist: String?

    private let coverSize: CGFloat = TokenSpacing._15

    var body: some View {
        HStack(spacing: TokenSpacing._3) {
            cover

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(title ?? "")
                    .font(.title3.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .lineLimit(1)
                Text(artist ?? "")
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cover: some View {
        Group {
            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
            } else {
                MEGAAssets.Image.audioIcon
                    .resizable()
                    .scaledToFit()
                    .padding(TokenSpacing._3)
            }
        }
        .frame(width: coverSize, height: coverSize)
        .background(TokenColors.Text.primary.swiftUI.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
    }
}

// MARK: - Preview

#Preview("Playlist") {
    ZStack {
        LinearGradient(
            colors: [
                TokenColors.Background.page.swiftUI,
                Color(red: 0.36, green: 0.07, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
            NowPlayingCompactHeader(coverImage: nil, title: "Orange (Live)", artist: "Arcy Drive")
                .padding(TokenSpacing._4)

            let previewItems = ["Orange (Live)", "Superbloomer (Live)", "Liquor Lips (Live)", "Dessert song (Live)"]
                .enumerated()
                .map { index, title in
                    AudioPlaylistItem(id: "\(index)", title: title)
                }
            PlaylistView(
                sourceName: "Arcy Drive",
                items: previewItems,
                currentTrackID: previewItems.first?.id,
                isVisible: true,
                onSelect: { _ in },
                onMove: { _, _ in },
                loadMetadata: { _ in AudioMetadata(title: nil, artist: "Arcy Drive", album: nil, artworkData: nil) }
            )
        }
    }
    .preferredColorScheme(.dark)
}
