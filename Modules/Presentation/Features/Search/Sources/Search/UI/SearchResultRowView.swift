import MEGASwiftUI
import SwiftUI

struct SearchResultRowView: View {
    @StateObject var viewModel: SearchResultRowViewModel
    
    var body: some View {
        content
            .listRowInsets(
                EdgeInsets(
                    top: -2,
                    leading: 12,
                    bottom: -2,
                    trailing: 16
                )
            )
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
    
    private var content: some View {
        HStack {
            HStack {
                thumbnail
                titleAndDescription
                Spacer()
            }
            moreButton
        }
        .taskForiOS14 {
            await viewModel.loadThumbnail()
        }
    }
    
    private var thumbnail: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
    }
    
    private var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(viewModel.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(.primary)
            Text(viewModel.subtitle)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
    }
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.contextButtonImage
        ) { button in
            viewModel.actions.contextAction(button)
        }
        .frame(width: 40, height: 60)
    }
}

struct SearchResultRowView_Previews: PreviewProvider {
    
    static var items: [SearchResultRowViewModel] {
        Array(0...10).map {
            .init(
                with: .init(
                    id: $0,
                    title: "title_\($0)",
                    description: "subtitle_\($0)",
                    properties: [],
                    thumbnailImageData: { UIImage(systemName: "scribble")?.pngData() ?? Data() },
                    type: .node
                ),
                contextButtonImage: UIImage(systemName: "ellipsis")!,
                previewContent: .init(
                    actions: [.init(title: "Select", imageName: "checkmark.circle", handler: { })],
                    previewMode: .preview({
                        UIHostingController(rootView: Text("Hello world"))
                    })
                ),
                actions: .init(
                    contextAction: { _ in },
                    selectionAction: {},
                    previewTapAction: {}
                )
            )
        }
    }
    static var previews: some View {
        
        List {
            ForEach(items) {
                SearchResultRowView(viewModel: $0)
            }
        }
        .listStyle(.plain)
    }
}
