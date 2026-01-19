import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct PhotoLibraryGlobalHeaderView<LeftContent: View, RightContent: View>: View {
    let leftContent: LeftContent
    let rightContent: RightContent

    init(
        @ViewBuilder leftContent: () -> LeftContent,
        @ViewBuilder rightContent: () -> RightContent
    ) {
        self.leftContent = leftContent()
        self.rightContent = rightContent()
    }

    var body: some View {
        ResultsHeaderView(
            leftView: { leftContent },
            rightView: { rightContent }
        )
        .padding(.horizontal, TokenSpacing._5)
        .background(TokenColors.Background.page.swiftUI.opacity(1.0))
    }
}

// Convenience initializer for timeline mode (text title + zoom control)
extension PhotoLibraryGlobalHeaderView where LeftContent == Text, RightContent == PhotoLibraryZoomMenuControl {
    init(title: String, zoomState: Binding<PhotoLibraryZoomState>) {
        self.init(
            leftContent: {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            },
            rightContent: {
                PhotoLibraryZoomMenuControl(zoomState: zoomState)
            }
        )
    }
}

// Convenience initializer for header without right content
extension PhotoLibraryGlobalHeaderView where RightContent == EmptyView {
    init(@ViewBuilder leftContent: () -> LeftContent) {
        self.leftContent = leftContent()
        self.rightContent = EmptyView()
    }
}
