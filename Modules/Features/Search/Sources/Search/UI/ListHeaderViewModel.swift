import SwiftUI

// Used to represent data rendered in the List section header
// in the Cloud Drive (SearchResultsView) when used in the Recent files display mode
// [SAO-2625]
public struct ListHeaderViewModel {
    public init(
        leadingText: String,
        icon: UIImage,
        trailingText: String
    ) {
        self.leadingText = leadingText
        self.icon = icon
        self.trailingText = trailingText
    }
    
    var leadingText: String
    var icon: UIImage
    var trailingText: String
}
