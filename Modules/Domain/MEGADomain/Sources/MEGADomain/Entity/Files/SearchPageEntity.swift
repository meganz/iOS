import Foundation

/**
 * Store pagination options used in searches
 */
public struct SearchPageEntity: Sendable {
    
    /// The first position in the list of results to be included in the returned page (starts from 0).
    public let startingOffset: Int
    /// The maximum number of results included in the page, or 0 to return all (remaining) results
    public let pageSize: Int
    
    public init(startingOffset: Int, pageSize: Int) {
        self.startingOffset = startingOffset
        self.pageSize = pageSize
    }
}
