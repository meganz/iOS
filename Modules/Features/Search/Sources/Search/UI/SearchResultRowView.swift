import MEGASwiftUI
import SwiftUI

struct SearchResultRowView: View {
    @StateObject var viewModel: SearchResultRowViewModel

    public var body: some View {
        HStack(spacing: 8) {
            thumbnail
            HStack {
                titleAndDescription
                Spacer()
                more
            }
        }
        .padding([.leading, .trailing])
        .frame(height: 65)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectionAction()
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
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            Text(viewModel.subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
        }
        .frame(height: 40)
    }

    private var more: some View {
        Image("moreList")
            .onTapGesture {
                viewModel.contextAction()
            }
    }
}

struct SearchResultRowView_Previews: PreviewProvider {
    static var previews: some View {
        let id = ResultId(id: "1")

        return SearchResultRowView(
            viewModel: .init(
                with: .init(
                    id: id,
                    title: "title_\(id)",
                    description: "subtitle_\(id)",
                    properties: [],
                    thumbnailImageData: { UIImage(systemName: "placeholder")?.pngData() ?? Data() },
                    type: .node
                ),
                contextAction: { },
                selectionAction: { }
            )
        )
    }
}
