import MEGASwiftUI
import SwiftUI

/// View shows content of a node in the thumbnails layout
/// it has two modes of rendering:
/// .vertical for files that show big preview
/// .horizontal for folders, that show small icon only
struct SearchResultThumbnailItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @ObservedObject var viewModel: SearchResultRowViewModel

    var body: some View {
        content
            .task {
                await viewModel.loadThumbnail()
            }
            .contextMenuWithPreview(
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
        switch viewModel.result.thumbnailDisplayMode {
        case .horizontal:
            HorizontalThumbnailView(viewModel: viewModel)
        case .vertical:
            VerticalThumbnailView(viewModel: viewModel)
        }
    }
}

extension PreviewContent {
    static let example: Self = .init(
        actions: [.init(title: "Select", imageName: "checkmark.circle", handler: { })],
        previewMode: .preview({
            UIHostingController(rootView: Text("Hello world"))
        })
    )
}

struct SearchResultThumbnailItemView_Previews: PreviewProvider {
    static func testView(mode: ResultCellLayout.ThumbnailMode) -> SearchResultThumbnailItemView {
        SearchResultThumbnailItemView(
            viewModel: .init(
                result: .previewResult(
                    idx: 1,
                    thumbnailDisplayMode: mode,
                    backgroundDisplayMode: .preview
                ),
                rowAssets: .example,
                colorAssets: .example,
                previewContent: .example,
                actions: .init(
                    contextAction: { _ in },
                    selectionAction: {},
                    previewTapAction: {}
                )
            )
        )
    }
    static var previews: some View {
        
        testView(mode: .horizontal)
            .previewDisplayName("Folder")
            .frame(width: 173, height: 214)
        
        testView(mode: .vertical)
            .previewDisplayName("File")
            .frame(width: 173, height: 214)
    }
}
