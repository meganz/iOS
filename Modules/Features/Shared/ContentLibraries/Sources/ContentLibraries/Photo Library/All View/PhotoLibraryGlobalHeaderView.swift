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
        .background(TokenColors.Background.page.swiftUI.opacity(1.0))
    }
}

// Convenience initializer for timeline mode (text title + zoom control)
extension PhotoLibraryGlobalHeaderView where LeftContent == Text, RightContent == ZoomMenuControlWrapper {
    init(title: String, zoomState: Binding<PhotoLibraryZoomState>, isEditing: Bool) {
        self.init(
            leftContent: {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            },
            rightContent: {
                ZoomMenuControlWrapper(zoomState: zoomState, isEditing: isEditing)
            }
        )
    }
}

struct ZoomMenuControlWrapper: View {
    @Binding var zoomState: PhotoLibraryZoomState
    let isEditing: Bool

    var body: some View {
        if !isEditing {
            PhotoLibraryZoomMenuControl(zoomState: $zoomState)
        }
    }
}

// Convenience initializer for header without right content
extension PhotoLibraryGlobalHeaderView where RightContent == EmptyView {
    init(@ViewBuilder leftContent: () -> LeftContent) {
        self.leftContent = leftContent()
        self.rightContent = EmptyView()
    }
}
