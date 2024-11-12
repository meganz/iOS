import ContentLibraries
import Foundation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct PhotoSearchResultItemView: View {
    @ObservedObject var viewModel: PhotoSearchResultItemViewModel
    
    var body: some View {
        MEGAList(title: viewModel.title)
            .titleLineLimit(1)
            .replaceLeadingView {
                PhotoCellImage(container: viewModel.thumbnailContainer)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .task {
                        await viewModel.loadThumbnail()
                    }
            }
            .titleSubstringAttribute(
                viewModel.searchText,
                compareOptions: .caseInsensitive,
                attributes: AttributeContainer()
                    .backgroundColor(TokenColors.Text.info.swiftUI)
            )
            .replaceTrailingView {
                Button {
                    // CC-8424 - Handle more button pressed
                } label: {
                    Image(uiImage: MEGAAssetsImageProvider.image(named: "moreList") ?? UIImage())
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(TokenColors.Background.page.swiftUI)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
    }
}
