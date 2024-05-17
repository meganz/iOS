import MEGADomain
import MEGAL10n
import MEGASwiftUI

extension VideoPlaylistEntity {
    
    func toVideoPlaylistCellPreviewEntity(thumbnailContainers: [any ImageContaining], durationText: String) -> VideoPlaylistCellPreviewEntity {
        VideoPlaylistCellPreviewEntity(
            imageContainers: thumbnailContainers,
            count: countText(thumbnailContainers: thumbnailContainers),
            duration: durationText,
            title: name,
            isExported: isLinkShared,
            type: type
        )
    }
    
    private func countText(thumbnailContainers: [any ImageContaining]) -> String {
        if thumbnailContainers.count == 0 {
            Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist
        } else if thumbnailContainers.count == 1 {
            "\(thumbnailContainers.count)" + " " + Strings.Localizable.video
        } else {
            "\(thumbnailContainers.count)" + " " + Strings.Localizable.videos
        }
    }
}
