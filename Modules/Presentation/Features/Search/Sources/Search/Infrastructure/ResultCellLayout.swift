import Foundation

/// difference between ResultCellLayout and PageLayout is the level of applying it
/// for the SearchResultsView, it can only switch between list and thumbnail
/// it does not know anything about two ways, cells can be display in the thumbnail layout,
/// this decision is made in the SearchResultThumbnailItemView as it decides
/// if node is rendered in vertical or horizontal mode (file vs folder)
/// For ResultProperties, they need to make decision where they want to be placed
/// without particular cell layout, hence the distinction
public enum ResultCellLayout: Equatable, Sendable, Hashable {
    case list
    case thumbnail
}

/// High level layout of the node collection page
public enum PageLayout: Equatable, Sendable {
    // uniform list of cells akin to table view
    case list
    /// a 2-column grid that shows:
    /// * folders in small rectangle and horizontal layout
    /// * files in bigger rectangle and vertical layout
    /// folders are show on the top of the list and files are shown below
    case thumbnail
    
    public mutating func toggle() {
        switch self {
        case .list:
            self = .thumbnail
        case .thumbnail:
            self = .list
        }
    }
}
