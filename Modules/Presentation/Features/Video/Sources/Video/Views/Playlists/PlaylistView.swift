import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct PlaylistView: View {
    
    @StateObject private var viewModel: VideoPlaylistsViewModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistsViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    var body: some View {
        VStack {
            newPlaylistView
            listView
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
        .alert(isPresented: $viewModel.shouldShowAddNewPlaylistAlert, viewModel.alertViewModel)
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
        VideoPlaylistsCollectionViewRepresenter(
            thumbnailUseCase: viewModel.thumbnailUseCase,
            viewModel: viewModel,
            videoConfig: videoConfig,
            router: router
        )
        .listStyle(PlainListStyle())
        .padding(.horizontal, 8)
    }
    
    private func favoritePlaylistCell(videoPlaylist: VideoPlaylistEntity) -> some View {
        let cellViewModel = videoPlaylistCellViewModel(videoPlaylist)
        return FavoritePlaylistCell(viewModel: cellViewModel, videoConfig: videoConfig, router: router)
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
    PlaylistView(
        viewModel: VideoPlaylistsViewModel(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
            thumbnailUseCase: Preview_ThumbnailUseCase(),
            videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
            syncModel: VideoRevampSyncModel(),
            alertViewModel: .preview
        ),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter()
    )
}

#Preview {
    PlaylistView(
        viewModel: VideoPlaylistsViewModel(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
            thumbnailUseCase: Preview_ThumbnailUseCase(),
            videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
            syncModel: VideoRevampSyncModel(),
            alertViewModel: .preview
        ),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter()
    )
    .preferredColorScheme(.dark)
}
