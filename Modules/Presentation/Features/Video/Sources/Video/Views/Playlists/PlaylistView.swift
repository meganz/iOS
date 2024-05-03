import MEGAL10n
import SwiftUI

struct PlaylistView: View {
    
    @StateObject private var viewModel: VideoPlaylistsViewModel
    private let videoConfig: VideoConfig
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistsViewModel,
        videoConfig: VideoConfig
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
    }
    
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
            viewModel.shouldShowAddNewPlaylistAlert = true
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
        .alert(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title, isPresented: $viewModel.shouldShowAddNewPlaylistAlert) {
            TextField(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder, text: $viewModel.playlistName)
            Button(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create) { }
                .keyboardShortcut(.defaultAction)
            Button(Strings.Localizable.cancel, role: .cancel) { }
        }
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

#Preview {
    Group {
        PlaylistView(viewModel: VideoPlaylistsViewModel(syncModel: VideoRevampSyncModel()), videoConfig: .preview)
        PlaylistView(viewModel: VideoPlaylistsViewModel(syncModel: VideoRevampSyncModel()), videoConfig: .preview)
            .preferredColorScheme(.dark)
    }
}
