import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct PhotoLibraryGlobalHeaderView: View {
    let monthTitle: String
    @Binding var zoomState: PhotoLibraryZoomState

    var body: some View {
        ResultsHeaderView(
            leftView: {
                Text(monthTitle)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            },
            rightView: {
                PhotoLibraryZoomMenuControl(zoomState: $zoomState)
            }
        )
        .padding(.horizontal, TokenSpacing._5)
        .background(TokenColors.Background.page.swiftUI.opacity(1.0))
    }
}
