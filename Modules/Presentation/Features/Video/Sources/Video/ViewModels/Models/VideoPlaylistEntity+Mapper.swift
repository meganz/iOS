import MEGADomain
import MEGAL10n
import MEGASwiftUI

extension VideoPlaylistEntity {
    
    func toVideoPlaylistCellPreviewEntity(thumbnailContainers: [any ImageContaining], durationText: String) -> VideoPlaylistCellPreviewEntity {
        VideoPlaylistCellPreviewEntity(
            imageContainers: thumbnailContainers,
            count: countText(),
            duration: durationText,
            title: name,
            isExported: isLinkShared
        )
    }
    
    private func countText() -> String {
        if count == 0 {
            Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist
        } else if count == 1 {
            "\(count)" + " " + Strings.Localizable.video
        } else {
            "\(count)" + " " + Strings.Localizable.videos
        }
    }
}
