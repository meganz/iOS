import MEGASwiftUI
import SwiftUI

struct SearchResultRowView: View {
    @StateObject var viewModel: SearchResultsRowViewModel
    var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: viewModel.thumbnailImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            HStack {
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

                Spacer()

                Button(action: {
                    viewModel.contextAction()
                }, label: {
                    Image("moreList")
                })
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectionAction()
        }
        .taskForiOS14 {
            await viewModel.loadThumbnail()
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
