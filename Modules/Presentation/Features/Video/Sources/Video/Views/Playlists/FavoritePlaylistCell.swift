import MEGAL10n
import SwiftUI

struct FavoritePlaylistCell: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        HStack {
            ThumbnailLayerView(videoConfig: videoConfig)
                .frame(width: 142, height: 80, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites)
                    .font(.subheadline)
                Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                    .font(.caption)
                    .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            Image(uiImage: videoConfig.rowAssets.moreImage)
                .foregroundColor(.secondary)
        }
        .padding(0)
    }
}

private struct ThumbnailLayerView: View {
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    let videoConfig: VideoConfig
    
    var body: some View {
        ZStack {
            colorScheme == .light
            ? videoConfig.colorAssets.emptyFavoriteThumbnailLightBackgroundColor
            : videoConfig.colorAssets.emptyFavoriteThumbnailDarkBackgroundColor
            
            VStack(spacing: 0) {
                HStack {
                    Image(uiImage: videoConfig.rowAssets.rectangleVideoStackPlaylistImage)
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, -16)
                .padding(.trailing, 4)
                
                Image(uiImage: videoConfig.rowAssets.favouritePlaylistThumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .foregroundColor(
                        colorScheme == .light
                        ? videoConfig.colorAssets.emptyFavoriteThumbnaillImageLightForegroundColor
                        : videoConfig.colorAssets.emptyFavoriteThumbnaillImageDarkForegroundColor
                    )
            }
            .padding(0)
        }
    }
}

struct FavoritePlaylistCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FavoritePlaylistCell(videoConfig: .preview)
                .frame(height: 80, alignment: .center)
            FavoritePlaylistCell(videoConfig: .preview)
                .frame(height: 80, alignment: .center)
                .preferredColorScheme(.dark)
        }
    }
}
