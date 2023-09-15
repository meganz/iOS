import MEGASwiftUI
import SwiftUI

struct SearchResultRowView: View {
    @StateObject var viewModel: SearchResultRowViewModel
    
    var body: some View {
        Button(
            action: viewModel.selectionAction,
            label: { content }
        )
        .listRowInsets(
            EdgeInsets(
                top: -2,
                leading: 12,
                bottom: -2,
                trailing: 16
            )
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
                .lineLimit(1)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            Text(viewModel.subtitle)
                .lineLimit(1)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
        }
    }
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.contextButtonImage
        ) { button in
            viewModel.contextAction(button)
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
                contextAction: { _ in },
                selectionAction: { }
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
