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
            ZStack(alignment: viewModel.isLoading ? .center : viewModel.isMediaRevampEnabled ? .topLeading : .bottomTrailing) {
                AlbumCellImage(
                    container: viewModel.thumbnailContainer,
                    isMediaRevampEnabled: viewModel.isMediaRevampEnabled
                )
                .overlay(
                    viewModel.isMediaRevampEnabled ? AnyView(albumCoverOverlay) : AnyView(viewModel.photoOverlay())
                )
                
                LinearGradient(gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.7), location: 0),
                    .init(color: Color.black.opacity(0.0), location: 1)
                ]), startPoint: .top, endPoint: .bottom)
                .opacity(viewModel.shouldShowGradient ? 1.0 : 0.0)
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1.0 : 0.0)
                
                if viewModel.isMediaRevampEnabled {
                    coverAttributes
                } else {
                    legacyCoverAttributes
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: viewModel.isMediaRevampEnabled ? TokenRadius.small : 6))
            
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
            foregroundColor: viewModel.isSelected ? TokenColors.Support.success.swiftUI : TokenColors.Icon.onColor.swiftUI,
            isMediaRevamp: viewModel.isMediaRevampEnabled
        )
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
                foregroundColor:
                    TokenColors.Components.selectionControlAlt.swiftUI,
                showBorder: false,
                isMediaRevamp: viewModel.isMediaRevampEnabled
            )
            .opacity(viewModel.isSelected ? 1.0 : 0.0)
            .padding(.top, 6)
            .padding(.leading, 6)
            
            Spacer()
            
            SharedLinkView(
                foregroundColor: viewModel.isPlaceholder ? TokenColors.Icon.secondary.swiftUI : TokenColors.Icon.onColor.swiftUI,
                isMediaRevampEnabled: viewModel.isMediaRevampEnabled)
            .opacity(viewModel.isLinkShared ? 1.0 : 0.0)
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
    }
    
    private var legacyCoverAttributes: some View {
        VStack {
            SharedLinkView(
                foregroundColor: viewModel.isPlaceholder ? TokenColors.Icon.secondary.swiftUI : TokenColors.Icon.onColor.swiftUI)
                .offset(x: 2, y: 0)
                .opacity(viewModel.isLinkShared ? 1.0 : 0.0)
            
            Spacer()
            
            checkMarkView
                .offset(x: -5, y: -5)
                .opacity(viewModel.shouldShowEditStateOpacity)
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
