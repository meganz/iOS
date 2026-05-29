import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
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
            ZStack(alignment: viewModel.isLoading ? .center : .topLeading) {
                AlbumCellImage(container: viewModel.thumbnailContainer)
                    .overlay(albumCoverOverlay)
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1.0 : 0.0)
                
                coverAttributes
            }
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))

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
    
    private var checkMarkForegroundColor: Color {
        if viewModel.isSelected {
            return TokenColors.Icon.accent.swiftUI
        } else {
            return TokenColors.Border.strong.swiftUI
        }
    }
    
    @ViewBuilder
    private var albumCoverOverlay: some View {
        if viewModel.selection.mode == .multiple, viewModel.isSelected {
            RoundedRectangle(cornerRadius: TokenRadius.small)
                .strokeBorder(
                    TokenColors.Icon.accent.swiftUI,
                    lineWidth: 2
                )
        } else if viewModel.isDisabled {
            TokenColors.Background.page.swiftUI.opacity(0.8)
        }
    }
    
    private var coverAttributes: some View {
        HStack(spacing: .zero) {
            CheckMarkView(
                markedSelected: viewModel.isSelected,
                foregroundColor: checkMarkForegroundColor,
                showBorder: false,
                isMediaRevamp: true
            )
            .opacity(viewModel.isSelected ? 1.0 : 0.0)
            .padding(.top, 6)
            .padding(.leading, 6)
            
            Spacer()
            
            SharedLinkView(
                foregroundColor: viewModel.isPlaceholder ? TokenColors.Icon.secondary.swiftUI : TokenColors.Icon.onColor.swiftUI)
            .opacity(viewModel.isLinkShared ? 1.0 : 0.0)
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
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
