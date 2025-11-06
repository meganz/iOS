import MEGADomain

/// Handles the fetching/mapping/filtering of content to be consumed in VideListViewModel.
/// This is used to separate concerns of breaching actor boundaries, when calling internal functions from different actors.
protocol VideoListViewModelContentProviderProtocol: Sendable {
    
    /// Returns the final list of nodes to be used in VideoListViewModel
    /// - Parameters:
    ///   - searchText: Search description if any, to filter nodes by.
    ///   - sortOrderType: Defines order of the returned nodes
    ///   - durationFilterOptionType: Filters nodes based on duration criteria, only including nodes that match this.
    ///   - locationFilterOptionType: Filters nodes based on location criteria, only including nodes that match this.
    /// - Returns: List of nodes to be displayed in VideoListView
    func search(by searchText: String, sortOrderType: SortOrderEntity, durationFilterOptionType: DurationChipFilterOptionType, locationFilterOptionType: LocationChipFilterOptionType) async throws -> [NodeEntity]
}
