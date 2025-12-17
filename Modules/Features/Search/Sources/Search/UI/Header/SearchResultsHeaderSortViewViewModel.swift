import MEGASwift
import SwiftUI

@MainActor
public final class SearchResultsHeaderSortViewViewModel: ObservableObject {
    @Published private(set) var selectedOption: SearchResultsSortOption
    @Published var showSortSheet: Bool = false
    public internal(set) var displaySortOptionsViewModel: SearchResultsSortOptionsViewModel

    private var continuation: AsyncStream<Void>.Continuation?

    public var tapEvents: AnyAsyncSequence<Void> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
        .eraseToAnyAsyncSequence()
    }

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

    func changeSelection() {
        continuation?.yield(())
        switch displaySortOptionsViewModel.sortOptions.count {
        case 1:
            let newSelection = displaySortOptionsViewModel.sortOptions[0]
            displaySortOptionsViewModel.tapHandler?(newSelection)
        case 2...:
            showSortSheet = true
        default:
            assertionFailure("Invalid sort options provided with count \(displaySortOptionsViewModel.sortOptions.count)")
        }
    }
}
