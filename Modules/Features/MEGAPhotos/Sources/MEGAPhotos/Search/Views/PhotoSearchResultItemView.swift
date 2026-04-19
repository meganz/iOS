import ContentLibraries
import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct PhotoSearchResultItemView: View {
    @ObservedObject var viewModel: PhotoSearchResultItemViewModel
    
    var body: some View {
        HStack(spacing: TokenSpacing._3) {
            PhotoCellImage(container: viewModel.thumbnailContainer)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                .task {
                    await viewModel.loadThumbnail()
                }

            HStack(spacing: 4) {
                if let labelImage = viewModel.labelImage {
                    Image(uiImage: labelImage)
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 9, height: 9)
                }

                Text(viewModel.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if viewModel.shouldShowFavourite {
                    Image(uiImage: MEGAAssets.UIImage.heart)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }

                if viewModel.shouldShowLink {
                    Image(uiImage: MEGAAssets.UIImage.link01)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }

            Spacer()

            ImageButtonWrapper(
                image: Image(uiImage: MEGAAssets.UIImage.moreList),
                imageColor: TokenColors.Icon.secondary.swiftUI
            ) { button in
                viewModel.moreButtonPressed(button)
            }
            .frame(width: 28, height: 28)
        }
        .padding(.leading, TokenSpacing._4)
        .padding(.trailing, TokenSpacing._5)
        .background(TokenColors.Background.page.swiftUI)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}
