import MEGADomain
import Search

public protocol FavouritesSearchResultsMapping: Sendable {
    func map(node: NodeEntity) -> SearchResult
}
