import Foundation
import MEGADomain
import MEGASdk

extension SearchPageEntity {
    
    func toMEGASearchPage() -> MEGASearchPage {
        MEGASearchPage(
            startingOffset: startingOffset,
            pageSize: pageSize)
    }
}
