import MEGASwiftUI
import SwiftUI

struct SearchResultRowView: View {
    @ObservedObject var viewModel: SearchResultRowViewModel
    @Binding var selected: Set<ResultId>
    @Binding var selectionMode: Bool
    
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
            .onTapGesture {
                viewModel.actions.selectionAction()
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
    
    private var content: some View {
        HStack {
            HStack {
                selectionIcon
                thumbnail
                titleAndDescription
                Spacer()
            }
            moreButton
        }
        .taskForiOS14 {
            await viewModel.loadThumbnail()
        }
        .contentShape(Rectangle())
        .frame(minHeight: 60)
    }
    
    var isSelected: Bool {
        selected.contains(viewModel.result.id)
    }
    
    @ViewBuilder var selectionIcon: some View {
        if selectionMode {
            Image(
                uiImage: isSelected ?
                viewModel.selectedCheckmarkImage :
                viewModel.unselectedCheckmarkImage
            )
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
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
    
    @ViewBuilder
    private var moreButton: some View {
        if !selectionMode {
            UIButtonWrapper(
                image: viewModel.contextButtonImage
            ) { button in
                viewModel.actions.contextAction(button)
            }
            .frame(width: 40, height: 60)
        }
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
                    type: .node,
                    thumbnailPreviewInfo: .init(
                        id: "1",
                        displayMode: .folder,
                        title: "Folder Title",
                        subtitle: "Info",
                        iconIndicatorPath: nil,
                        duration: "2:00",
                        isVideoIconHidden: true,
                        hasThumbnail: true,
                        thumbnailImageData: { .init() },
                        propertiesData: { [] },
                        downloadVisibilityData: { false }
                    )
                ),
                rowAssets: .init(
                    contextImage: UIImage(systemName: "ellipsis")!,
                    itemSelected: UIImage(systemName: "ellipsis")!,
                    itemUnselected: UIImage(systemName: "ellipsis")!,
                    playImage: UIImage(systemName: "ellipsis")!,
                    downloadedImage: UIImage(systemName: "ellipsis")!,
                    moreList: UIImage(systemName: "ellipsis")!,
                    moreGrid: UIImage(systemName: "ellipsis")!
                ),
                colorAssets: .init(
                    F7F7F7: Color("F7F7F7"),
                    _161616: Color("161616"),
                    _545458: Color("545458"),
                    CE0A11: Color("CE0A11"),
                    F30C14: Color("F30C14"),
                    F95C61: Color("F95C61"),
                    F7363D: Color("F7363D"),
                    _1C1C1E: Color("1C1C1E")
                ),
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
                SearchResultRowView(
                    viewModel: $0,
                    selected: .constant([]),
                    selectionMode: .constant(true)
                )
            }
        }
        .listStyle(.plain)
    }
}
