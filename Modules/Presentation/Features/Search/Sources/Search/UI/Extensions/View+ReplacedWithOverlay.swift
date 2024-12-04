import MEGASwiftUI
import SwiftUI

extension View {
    /// Visually replaces `self` with an overlay that allows context menu interaction
    /// This function is intended for search results item views to avoid double rendering issue in [SAO-1743]
    func replacedByContextMenuWithPreview<Content: View>(
        actions: [UIAction],
        @ViewBuilder sourcePreview: @escaping () -> Content,
        contentPreviewProvider: @escaping UIContextMenuContentPreviewProvider,
        didTapPreview: @escaping () -> Void,
        didSelect: @escaping () -> Void
    ) -> some View {
        self
            .opacity(0)
            .contextMenuWithPreview(
                actions: actions,
                sourcePreview: {
                    // We should disable accessibility for source sourcePreview
                    // otherwise the accessibility labels will be duplicated
                    sourcePreview()
                        .accessibilityElement(children: .ignore)
                },
                contentPreviewProvider: contentPreviewProvider,
                didTapPreview: didTapPreview,
                didSelect: didSelect
            )
    }
}
