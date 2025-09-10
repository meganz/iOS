import MEGASwiftUI
import SwiftUI

/// View shows content of a node in the Grid layout
public struct SearchResultThumbnailItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    @ObservedObject var viewModel: SearchResultRowViewModel
    var selected: Binding<Set<ResultId>>
    var selectionEnabled: Binding<Bool>
    
    public var body: some View {
        content
            .task {
                await viewModel.loadThumbnail()
            }
            .replacedByContextMenuWithPreview(
                actions: viewModel.previewContent.actions.toUIActions,
                sourcePreview: {
                    content
                },
                contentPreviewProvider: {
                    switch viewModel.previewContent.previewMode {
                    case let .preview(contentPreviewProvider):
                        return contentPreviewProvider()
                    case .noPreview:
                        return nil
                    }
                },
                didTapPreview: viewModel.actions.previewTapAction,
                didSelect: viewModel.actions.selectionAction
            )
    }
    
    @ViewBuilder
    private var content: some View {
        SearchResultThumbnailView(
            viewModel: viewModel,
            selected: selected,
            selectionEnabled: selectionEnabled
        )
    }
}

extension PreviewContent {
    @MainActor static let example: Self = .init(
        actions: [.init(title: "Select", imageName: "checkmark.circle", handler: { })],
        previewMode: .preview({
            UIHostingController(rootView: Text("Hello world"))
        })
    )
}

#Preview("Folder") {
    SearchResultThumbnailItemView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                backgroundDisplayMode: .preview
            ),
            query: { nil },
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}

#Preview("File") {
    SearchResultThumbnailItemView(
        viewModel: .init(
            result: .previewResult(
                idx: 1,
                backgroundDisplayMode: .preview
            ),
            query: { nil },
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(
                contextAction: { _ in },
                selectionAction: {},
                previewTapAction: {}
            ),
            swipeActions: []
        ),
        selected: .constant([]),
        selectionEnabled: .constant(false)
    )
    .frame(width: 173, height: 214)
}
