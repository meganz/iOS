import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

// MARK: - Playlist

struct PlaylistView: View {
    let sourceName: String?
    let items: [AudioPlaylistItem]
    let onSelect: (AudioPlaylistItem) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                ForEach(items) { item in
                    PlaylistRow(item: item)
                        .padding(.horizontal, TokenSpacing._5)
                        .contentShape(Rectangle())
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: TokenRadius.small))
                        .onTapGesture { onSelect(item) }
                        .listRowSeparator(.hidden)
                        .listRowBackground(item.isCurrent ? TokenColors.Button.secondary.swiftUI : Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                .onMove(perform: onMove)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let sourceName, !sourceName.isEmpty {
            Text(headerText(sourceName: sourceName))
                .font(.subheadline)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

    private let thumbnailSize: CGFloat = TokenSpacing._11

    var body: some View {
        HStack(spacing: TokenSpacing._2) {
            thumbnail

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                HStack(spacing: TokenSpacing._1) {
                    if item.isCurrent {
                        MEGAAssets.Image.monoWaveformSmallThinOutline
                            .resizable()
                            .scaledToFit()
                            .frame(width: TokenSpacing._5, height: TokenSpacing._5)
                    }
                    Text(item.title)
                        .font(.body)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .lineLimit(1)
                }

                Text(item.artist ?? "")
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
                    .opacity(item.artist == nil ? 0 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MEGAAssets.Image.monoQueueLineMediumThinOutline
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .frame(width: thumbnailSize, height: thumbnailSize)
        }
        .frame(height: 60)
    }

    private var thumbnail: some View {
        Group {
            if let image = item.thumbnail {
                Image(uiImage: image)
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

            PlaylistView(
                sourceName: "Arcy Drive",
                items: [
                    .init(id: "1", title: "Orange (Live)", artist: "Arcy Drive", thumbnail: nil, isCurrent: true),
                    .init(id: "2", title: "Superbloomer (Live)", artist: "Arcy Drive", thumbnail: nil, isCurrent: false),
                    .init(id: "3", title: "Liquor Lips (Live)", artist: "Arcy Drive", thumbnail: nil, isCurrent: false),
                    .init(id: "4", title: "Dessert song (Live)", artist: "Arcy Drive", thumbnail: nil, isCurrent: false)
                ],
                onSelect: { _ in },
                onMove: { _, _ in }
            )
        }
    }
    .preferredColorScheme(.dark)
}
