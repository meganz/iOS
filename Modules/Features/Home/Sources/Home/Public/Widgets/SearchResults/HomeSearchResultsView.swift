import Search
import SwiftUI
struct HomeResultsSearchableView: View {
    @Environment(\.isSearching) private var isSearching
    let viewModel: SearchResultsContainerViewModel
    @Binding var searchBecameActive: Bool

    var body: some View {
        SearchResultsContainerView(viewModel: viewModel)
            .onChange(of: isSearching) { isSearching in
                searchBecameActive = isSearching
            }
    }
}
