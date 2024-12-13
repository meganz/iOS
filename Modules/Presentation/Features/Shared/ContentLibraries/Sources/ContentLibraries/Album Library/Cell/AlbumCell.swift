import Foundation
import MEGADesignToken
import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct AlbumCell: View {
    @StateObject private var viewModel: AlbumCellViewModel
    
    public init(viewModel: @autoclosure @escaping () -> AlbumCellViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel() )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: viewModel.isLoading ? .center : .bottomTrailing) {
                PhotoCellImage(
                    container: viewModel.thumbnailContainer,
                    bgColor: TokenColors.Background.surface2.swiftUI
                )
                .overlay(viewModel.photoOverlay())
                .cornerRadius(6)
                
                GeometryReader { geo in
                    LinearGradient(colors: [TokenColors.Text.primary.swiftUI, .clear], startPoint: .top, endPoint: .bottom)
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
                    .foregroundStyle(!viewModel.isDisabled ? TokenColors.Text.primary.swiftUI : TokenColors.Text.disabled.swiftUI)
                
                Text("\(viewModel.numberOfNodes)")
                    .font(.footnote)
                    .foregroundStyle(!viewModel.isDisabled ?  TokenColors.Text.secondary.swiftUI : TokenColors.Text.disabled.swiftUI)
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
        .gesture(viewModel.isOnTapGestureEnabled ? tap : nil)
    }
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.onAlbumTap()
    }}
    
    private var checkMarkView: some View {
        CheckMarkView(
            markedSelected: viewModel.isSelected,
            foregroundColor: viewModel.isSelected ? TokenColors.Button.primary.swiftUI : TokenColors.Icon.onColor.swiftUI
        )
    }
}

#Preview {
    AlbumCell(
        viewModel: AlbumCellViewModel(
            thumbnailLoader: Preview_ThumbnailLoader(),
            monitorUserAlbumPhotosUseCase: Preview_MonitorUserAlbumPhotosUseCase(),
            nodeUseCase: Preview_NodeUseCase(),
            sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
            sensitiveDisplayPreferenceUseCase: Preview_SensitiveDisplayPreferenceUseCase(),
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
            selection: AlbumSelection()
        )
    )
}
