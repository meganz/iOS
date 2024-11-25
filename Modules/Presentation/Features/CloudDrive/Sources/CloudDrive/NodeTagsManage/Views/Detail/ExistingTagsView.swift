import SwiftUI

struct ExistingTagsView: View {
    @ObservedObject var viewModel: ExistingTagsViewModel

    var body: some View {
        if viewModel.isLoading {
            ExistingTagsLoadingView()
        } else {
            ScrollView {
                NodeTagsView(viewModel: viewModel.tagsViewModel)
            }
        }
    }
}
