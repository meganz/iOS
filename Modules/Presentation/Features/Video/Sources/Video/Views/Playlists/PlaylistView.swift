import MEGADomain
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
        .task {
            await viewModel.onViewAppeared()
        }
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
        List(viewModel.videoPlaylists, id: \.id) { videoPlaylist in
            if videoPlaylist.isSystemVideoPlaylist {
                favoritePlaylistCell(videoPlaylist: videoPlaylist)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init())
            } else {
                UserPlaylistCell(
                    viewModel: videoPlaylistCellViewModel(videoPlaylist),
                    videoConfig: videoConfig
                )
                .listRowSeparator(.hidden)
                .listRowInsets(.init())
            }
        }
        .listStyle(PlainListStyle())
        .padding(.horizontal, 8)
    }
    
    private func favoritePlaylistCell(videoPlaylist: VideoPlaylistEntity) -> some View {
        let cellViewModel = videoPlaylistCellViewModel(videoPlaylist)
        return FavoritePlaylistCell(viewModel: cellViewModel, videoConfig: videoConfig)
            .listRowSeparator(.hidden)
            .listRowInsets(.init())
    }
    
    private func videoPlaylistCellViewModel(_ videoPlaylist: VideoPlaylistEntity) -> VideoPlaylistCellViewModel {
        VideoPlaylistCellViewModel(
            thumbnailUseCase: viewModel.thumbnailUseCase, 
            videoPlaylistContentUseCase: viewModel.videoPlaylistContentUseCase,
            videoPlaylistEntity: videoPlaylist,
            onTapMoreOptions: { _ in }
        )
    }
}

#Preview {
    Group {
        PlaylistView(
            viewModel: VideoPlaylistsViewModel(
                videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
                thumbnailUseCase: Preview_ThumbnailUseCase(),
                videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
                syncModel: VideoRevampSyncModel()
            ),
            videoConfig: .preview
        )
        PlaylistView(
            viewModel: VideoPlaylistsViewModel(
                videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
                thumbnailUseCase: Preview_ThumbnailUseCase(),
                videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
                syncModel: VideoRevampSyncModel()
            ),
            videoConfig: .preview
        )
        .preferredColorScheme(.dark)
    }
}
