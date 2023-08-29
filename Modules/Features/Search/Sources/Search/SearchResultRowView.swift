import SwiftUI

struct SearchResultRowView: View {
    @StateObject var viewModel: SearchResultsRowViewModel

    var body: some View {
        HStack(spacing: 8) {
            if let uiImage = viewModel.thumbnailImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

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
                    // TODO: - Connect more action
                }, label: {
                    Image("moreList")
                })
            }
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
                    menuBuilder: {
                        .init()
                    },
                    type: .node
                )
            )
        )
    }
}
