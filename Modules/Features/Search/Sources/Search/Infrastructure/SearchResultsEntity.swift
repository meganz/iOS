/// Represents a full response from search provider with given search query
///  contains a collection of results
///  and collection of chips (those are static but have potential be dynamically adjust depending on the context)
public struct SearchResultsEntity {
    public let results: [SearchResult]
    public let chips: [SearchChipEntity]
    
    public init(
        results: [SearchResult],
        chips: [SearchChipEntity]
    ) {
        self.results = results
        self.chips = chips
    }
}
