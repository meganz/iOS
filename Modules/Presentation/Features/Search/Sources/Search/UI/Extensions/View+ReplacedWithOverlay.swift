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
                    sourcePreview()
                    // Our QA uses Appium to run automation test, the overlay will cause duplicated accessibility identifiers
                    // and mess up the result of Appium's search query.
                    // In order to avoid such issue, we override the `identifier` of the
                    // elements inside the overlay so that Appium can still locate the elements correctly.
                        .accessibilityIdentifier("--overlayId--")
                    // We also need to disable accessibility for the overlay so that its accessibility labels will not be read out.
                        .accessibilityHidden(true)
                },
                contentPreviewProvider: contentPreviewProvider,
                didTapPreview: didTapPreview,
                didSelect: didSelect
            )
    }
}
