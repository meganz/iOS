import SwiftUI
import UIKit

extension View {
    public func contextMenuWithPreview<Content: View>(
        actions: [UIAction],
        @ViewBuilder sourcePreview: @escaping () -> Content, // content to be tapped on and expanded
        contentPreviewProvider: @escaping UIContextMenuContentPreviewProvider, // creates view controller to preview, can return nil
        didTapPreview: @escaping () -> Void, // triggered when preview upon expansion is tapped
        didSelect: @escaping () -> Void // triggered when content before expansion is tapped
    ) -> some View {
        self.overlay(
            InteractionView(
                contentPreviewProvider: contentPreviewProvider,
                sourcePreview: sourcePreview,
                menu: UIMenu(title: "", children: actions),
                didTapPreview: didTapPreview,
                didSelect: didSelect
            )
        )
    }
}
