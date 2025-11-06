import Foundation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

public struct ChatMediaQualityView: View {
    @StateObject private var viewModel: ChatMediaQualityViewModel
    
    public init(viewModel: @autoclosure @escaping () -> ChatMediaQualityViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            imageQualityView
            videoQualityView
        }
        .noInternetViewModifier()
        .pageBackground()
        .navigationTitle(Strings.Localizable.Settings.Chat.MediaQuality.title)
    }
    
    private var imageQualityView: some View {
        Button(action: viewModel.imageQualityViewTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.MediaQuality.Image.title,
                subtitle: viewModel.imageMediaQuality.localisedName
            )
            .trailingChevron()
        }
        .bottomSheet(
            isPresented: $viewModel.isImageQualityBottomSheetPresented,
            detents: [.fixed(260)],
            showDragIndicator: true,
            cornerRadius: TokenRadius.large) {
                imageQualityListView
            }
    }
    
    private var videoQualityView: some View {
        Button(action: viewModel.videoQualityViewTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.MediaQuality.Video.title,
                subtitle: viewModel.videoMediaQuality.localisedName
            )
            .trailingChevron()
        }
        .bottomSheet(
            isPresented: $viewModel.isVideoQualityBottomSheetPresented,
            detents: [.fixed(300)],
            showDragIndicator: true,
            cornerRadius: TokenRadius.large) {
                videoQualityListView
            }
    }
    
    private var imageQualityListView: some View {
        MEGAList(contentView: {
            ForEach(viewModel.imageQualityOptions) { imageMediaQuality in
                Button(action: { viewModel.imageQualityOptionTapped(imageMediaQuality)
                }, label: {
                    MEGAList(
                        title: imageMediaQuality.localisedName,
                        subtitle: imageMediaQuality.localisedDescription
                    )
                    .trailingImage(icon: MEGAAssets.Image.check)
                    .trailingImageHidden(viewModel.imageMediaQuality != imageMediaQuality)
                })
            }
        }, headerView: {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.MediaQuality.Image.title
            )
            .titleFont(.headline)
            .padding([.top], TokenSpacing._6)
        })
        .pageBackground()
    }
    
    private var videoQualityListView: some View {
        MEGAList(contentView: {
            ForEach(viewModel.videoQualityOptions) { videoMediaQuality in
                Button(action: { viewModel.videoQualityOptionTapped(videoMediaQuality)
                }, label: {
                    MEGAList(
                        title: videoMediaQuality.localisedName
                    )
                    .trailingImage(icon: MEGAAssets.Image.check)
                    .trailingImageHidden(viewModel.videoMediaQuality != videoMediaQuality)
                })
            }
        }, headerView: {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.MediaQuality.Video.title
            )
            .titleFont(.headline)
            .padding([.top], TokenSpacing._6)
        })
        .pageBackground()
    }
}
