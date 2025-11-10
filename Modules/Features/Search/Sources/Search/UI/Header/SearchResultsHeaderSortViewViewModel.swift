import SwiftUI

@MainActor
public final class SearchResultsHeaderSortViewViewModel: ObservableObject {
    @Published var selectedOption: SearchResultsSortOption
    @Published var showSortSheet: Bool = false
    public var displaySortOptionsViewModel: SearchResultsSortOptionsViewModel

    public init(
        selectedOption: SearchResultsSortOption,
        displaySortOptionsViewModel: SearchResultsSortOptionsViewModel
    ) {
        self.selectedOption = selectedOption
        self.displaySortOptionsViewModel = displaySortOptionsViewModel
    }

    public func selectionChanged(to option: SearchResultsSortOption) {
        showSortSheet = false
        selectedOption = option
    }
}
