/// Represents a full response from search provider with given search query
///  contains a collection of results
///  and collection of chips (those are static but have potential be dynamically adjust depending on the context)
public struct SearchResultsEntity: Sendable {
    public let results: [SearchResult]
    public let availableChips: [SearchChipEntity] // represents all chips that can be selected
    public let appliedChips: [SearchChipEntity] // which chips where applied in the given results

    public init(
        results: [SearchResult],
        availableChips: [SearchChipEntity],
        appliedChips: [SearchChipEntity]
    ) {
        self.results = results
        self.availableChips = availableChips
        self.appliedChips = appliedChips
    }
}

extension SearchResultsEntity {
    func isApplied(chip: SearchChipEntity) -> Bool {
        appliedChips.map(\.id).contains(chip.id)
    }
}
