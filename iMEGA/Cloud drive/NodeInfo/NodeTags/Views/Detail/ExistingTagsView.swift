import SwiftUI

struct ExistingTagsView: View {
    @ObservedObject var viewModel: ExistingTagsViewModel

    var body: some View {
        ScrollView {
            ForEach(viewModel.formattedTags, id: \.self) { tag in
                if viewModel.isSelected(tag) {
                    NodeTagSelectedView(tag: tag)
                } else {
                    NodeTagNormalView(tag: tag)
                }
            }
        }
    }
}
