import Foundation

struct TableDataSourceConfiguration<Item> {

    let numberOfSections: () -> Int

    let numberOfRows: (
        _ inSection: Int
    ) -> Int

    let itemAtIndexPath: (
        _ indexPath: IndexPath
    ) -> Item?

    let headerTitle: (
        _ forSection: Int
    ) -> String?
}
