import SwiftUI

@MainActor
final class SearchResultsHeaderViewModeViewModel: ObservableObject {
    @Published var selectedViewMode: SearchResultsViewMode
    let availableViewModes: [SearchResultsViewMode]

    var image: Image { selectedViewMode.icon }
    var title: String { selectedViewMode.title }

    init(selectedViewMode: SearchResultsViewMode, availableViewModes: [SearchResultsViewMode]) {
        self.selectedViewMode = selectedViewMode
        self.availableViewModes = availableViewModes
    }
}
