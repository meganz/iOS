import MEGASwiftUI
import SwiftUI

struct SearchResultRowView: View {
    @StateObject var viewModel: SearchResultRowViewModel
    
    var body: some View {
        Button(
            action: viewModel.selectionAction,
            label: { content }
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
        .padding()
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
    
    private var moreButton: some View {
        UIButtonWrapper(
            image: UIImage(named: "moreList") ?? UIImage()
        ) { button in
            viewModel.contextAction(button)
        }
        .frame(width: 50, height: 50)
    }
}

 struct SearchResultRowView_Previews: PreviewProvider {
    static var previews: some View {
        let id = ResultId(1)

        return SearchResultRowView(
            viewModel: .init(
                with: .init(
                    id: id,
                    title: "title_\(id)",
                    description: "subtitle_\(id)",
                    properties: [],
                    thumbnailImageData: { UIImage(systemName: "scribble")?.pngData() ?? Data() },
                    type: .node
                ),
                contextAction: { _ in },
                selectionAction: { }
            )
        )
    }
 }
