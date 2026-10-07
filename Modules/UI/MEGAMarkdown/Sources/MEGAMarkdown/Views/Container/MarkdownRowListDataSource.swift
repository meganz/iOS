import CoreGraphics

/// The items of a `MarkdownRowList`. An item is one cell of the list. A caller may map one model row to several items.
@MainActor
package protocol MarkdownRowListDataSource: AnyObject {
    var itemCount: Int { get }
    /// Sets `cell.contentConfiguration` for the item. Called for a new cell and again for a kept cell.
    func configure(_ cell: MarkdownRowCell, forItem item: Int)
    /// A guess of the item's height before its cell sizes itself. Called on the main thread for every item.
    func estimatedHeight(ofItem item: Int, using estimator: MarkdownRowEstimator) -> CGFloat
    /// True for an item that can change its size by itself, for example a row with an image that loads later.
    /// Its cell sizes itself every time it shows.
    func alwaysSizes(item: Int) -> Bool
}
