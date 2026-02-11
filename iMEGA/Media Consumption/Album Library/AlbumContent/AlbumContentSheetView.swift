import MEGAUIComponent
import SwiftUI

struct AlbumContentSheetView: View {
    @StateObject var viewModel: AlbumActionSheetViewModel
    let onDismiss: (@escaping () -> Void) -> Void
    
    var body: some View {
        MEGAList(contentView: {
            ForEach(viewModel.sheetActions) { action in
                Button {
                    onDismiss(action.action)
                } label: {
                    MEGAList(
                        title: action.title
                    )
                    .leadingImage(action.icon)
                    .leadingImageColor(action.iconColor)
                    .leadingImageSize(CGSize(width: 24, height: 24))
                    .titleColor(action.titleColor)
                    .titleFont(.body)
                    .setPadding(.zero)
                }
            }
        }, headerView: {
            MEGAList(
                title: viewModel.title
            )
            .leadingImage(icon: viewModel.thumbnailContainer.image)
            .leadingImageSize(CGSize(width: 24, height: 24))
            .titleFont(.body.weight(.semibold))
            .setPadding(.zero)
        })
        .pageBackground()
        .task {
            await viewModel.loadAlbumCoverThumbnail()
        }
    }
}
