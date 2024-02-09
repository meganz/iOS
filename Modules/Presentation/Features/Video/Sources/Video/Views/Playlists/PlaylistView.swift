import MEGAL10n
import SwiftUI

struct PlaylistView: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        VStack {
            newPlaylistView
            listView
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    private var newPlaylistView: some View {
        HStack(spacing: 8) {
            addPlaylistButton
            
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.newPlaylist)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(videoConfig.colorAssets.primaryTextColor)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], 8)
    }
    
    private var addPlaylistButton: some View {
        Button {
            
        } label: {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                
                Image(uiImage: videoConfig.rowAssets.addPlaylistImage.withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .frame(width: 22, height: 22)
                    .tint(videoConfig.colorAssets.addPlaylistButtonTextColor)
            }
        }
        .tint(videoConfig.colorAssets.addPlaylistButtonBackgroundColor)
        .frame(width: 44, height: 44)
    }
    
    private var listView: some View {
        List {
            FavoritePlaylistCell(videoConfig: videoConfig)
                .listRowSeparator(.hidden)
                .listRowInsets(.init())
        }
        .listStyle(PlainListStyle())
        .padding(.horizontal, 8)
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlaylistView(videoConfig: .preview)
            PlaylistView(videoConfig: .preview)
                .preferredColorScheme(.dark)
        }
    }
}
