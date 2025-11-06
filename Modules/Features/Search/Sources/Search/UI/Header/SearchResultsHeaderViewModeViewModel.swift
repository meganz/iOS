import SwiftUI

@MainActor
public final class SearchResultsHeaderViewModeViewModel: ObservableObject {
    @Published public var selectedViewMode: SearchResultsViewMode
    @Published public var availableViewModes: [SearchResultsViewMode]

    var image: Image { selectedViewMode.icon }
    var title: String { selectedViewMode.title }

    public init(selectedViewMode: SearchResultsViewMode, availableViewModes: [SearchResultsViewMode]) {
        self.selectedViewMode = selectedViewMode
        self.availableViewModes = availableViewModes
    }
}
