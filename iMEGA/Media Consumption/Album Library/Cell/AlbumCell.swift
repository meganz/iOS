import MEGADesignToken
import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct AlbumCell: View {
    @StateObject var viewModel: AlbumCellViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: viewModel.isLoading ? .center : .bottomTrailing) {
                PhotoCellImage(
                    container: viewModel.thumbnailContainer,
                    bgColor: isDesignTokenEnabled
                    ? TokenColors.Background.surface2.swiftUI
                    : MEGAAppColor.Gray._EBEBEB.color
                )
                /// An overlayView to enhance visual selection thumbnail image. Requested by designers to not use design tokens for this one.
                .overlay(Color.black000000.opacity(isDesignTokenEnabled && viewModel.isSelected ? 0.2 : 0.0))
                .cornerRadius(6)
                
                GeometryReader { geo in
                    LinearGradient(colors: [isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : MEGAAppColor.Black._000000.color, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.size.height / 2)
                        .cornerRadius(5, corners: [.topLeft, .topRight])
                        .opacity(viewModel.isLinkShared ? 0.4 : 0.0)
                }
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1.0 : 0.0)
                
                VStack {
                    SharedLinkView()
                        .offset(x: 2, y: 0)
                        .opacity(viewModel.isLinkShared ? 1.0 : 0.0)
                    
                    Spacer()
                    
                    checkMarkView
                        .offset(x: -5, y: -5)
                        .opacity(viewModel.shouldShowEditStateOpacity)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.caption)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary)
                
                Text("\(viewModel.numberOfNodes)")
                    .font(.footnote)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : Color.secondary)
            }
        }
        .opacity(viewModel.opacity)
        .task {
            await viewModel.loadAlbumThumbnail()
        }
        .task {
            await viewModel.monitorCoverPhotoSensitivity()
        }
        .task {
            await viewModel.monitorAlbumPhotos()
        }
        .onTapGesture {
            viewModel.onAlbumTap()
        }
    }
    
    private var checkMarkView: some View {
        if isDesignTokenEnabled {
            CheckMarkView(
                markedSelected: viewModel.isSelected,
                foregroundColor: viewModel.isSelected ? TokenColors.Support.success.swiftUI : TokenColors.Icon.onColor.swiftUI
            )
        } else {
            CheckMarkView(
                markedSelected: viewModel.isSelected,
                foregroundColor: viewModel.isSelected ? MEGAAppColor.Green._34C759.color : MEGAAppColor.Photos.photoSelectionBorder.color
            )
        }
    }
}

#Preview {
    AlbumCell(
        viewModel: AlbumCellViewModel(
            thumbnailLoader: Preview_ThumbnailLoader(),
            monitorAlbumsUseCase: Preview_MonitorAlbumsUseCase(),
            nodeUseCase: Preview_NodeUseCase(),
            sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
            contentConsumptionUserAttributeUseCase: Preview_ContentConsumptionUserAttributeUseCase(),
            albumCoverUseCase: Preview_AlbumCoverUseCase(),
            album: AlbumEntity(
                id: 1, name: "Album name",
                coverNode: nil,
                count: 1, type: .favourite,
                creationTime: nil,
                modificationTime: nil,
                sharedLinkStatus: .exported(false),
                metaData: AlbumMetaDataEntity(
                    imageCount: 12,
                    videoCount: 12
                )
            ),
            selection: AlbumSelection(),
            selectedAlbum: Binding.constant(nil)
        )
    )
}
