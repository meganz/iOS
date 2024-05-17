import SwiftUI

struct PlaylistContentView: View {
    
    let videoConfig: VideoConfig
    let previewEntity: VideoPlaylistCellPreviewEntity
    let onTapAddButton: () -> Void
    let onTapPlayButton: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            PlaylistContentHeaderView(
                videoConfig: videoConfig,
                previewEntity: previewEntity,
                onTapAddButton: onTapAddButton,
                onTapPlayButton: onTapPlayButton
            )
            
            Spacer()
        }
    }
}

// MARK: Preview

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            imageContainers: [],
            count: "24 Videos",
            duration: "3:05:20",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: false,
            type: .favourite
        ),
        onTapAddButton: {},
        onTapPlayButton: {}
    )
}

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            imageContainers: [],
            count: "24 Videos",
            duration: "3:05:20",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: false,
            type: .user
        ),
        onTapAddButton: {},
        onTapPlayButton: {}
    )
    .preferredColorScheme(.dark)
}
