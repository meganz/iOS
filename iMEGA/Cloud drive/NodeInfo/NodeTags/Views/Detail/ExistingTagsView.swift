import SwiftUI

struct ExistingTagsView: View {
    @ObservedObject var viewModel: ExistingTagsViewModel

    var body: some View {
        ScrollView {
            HStack {
                ForEach(viewModel.formattedTags, id: \.self) { tag in
                    if viewModel.isSelected(tag) {
                        SelectedTagView(tag: tag)
                    } else {
                        NormalTagView(tag: tag)
                    }
                }
            }
        }
    }
}
