import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct PhotoLibraryGlobalHeaderView: View {
    let monthTitle: String
    @ObservedObject var viewModel: PhotoLibraryModeAllCollectionViewModel

    var body: some View {
        ResultsHeaderView(
            leftView: {
                Text(monthTitle)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            },
            rightView: {
                PhotoLibraryZoomMenuControl(zoomState: $viewModel.zoomState)
            }
        )
        .padding(.horizontal, TokenSpacing._5)
        .background(TokenColors.Background.page.swiftUI.opacity(1.0))
    }
}
