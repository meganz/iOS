import Search
import SwiftUI

struct HomeSearchableView<Content: View>: View {
    @Environment(\.isSearching) private var isSearching
    @Binding var searchBecameActive: Bool

    private let content: () -> Content

    init(searchBecameActive: Binding<Bool>,
         @ViewBuilder content: @escaping () -> Content) {
        _searchBecameActive = searchBecameActive
        self.content = content
    }

    var body: some View {
        content()
            .onChange(of: isSearching) { isSearching in
                searchBecameActive = isSearching
            }
    }
}
