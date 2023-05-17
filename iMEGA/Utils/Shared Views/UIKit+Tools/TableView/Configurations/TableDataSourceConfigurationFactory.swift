import Foundation

struct TableDataSourceConfigurationFactory<CellItem> {
    let produce: (
        _ itemData: [CellItem]
    ) -> TableDataSourceConfiguration<CellItem>
}

extension TableDataSourceConfigurationFactory {

    static var simple: Self {
        Self.init { items -> TableDataSourceConfiguration<CellItem> in
            return TableDataSourceConfiguration<CellItem>(
                numberOfSections: { () -> Int in
                    1
                }, numberOfRows: { _ in
                    items.count
                }, itemAtIndexPath: { indexPath in
                    return items[safe: indexPath.row]
                }, headerTitle: { _ -> String? in
                    nil
                }
            )
        }
    }
}
extension TableDataSourceConfigurationFactory where CellItem: Comparable {

    static var sorted: (Reader<[CellItem], [CellItem]>) -> Self {
        return { reader in
            Self { items -> TableDataSourceConfiguration<CellItem> in
                let sortedItems = reader.runReader(items)
                return TableDataSourceConfiguration<CellItem>(
                    numberOfSections: { () -> Int in
                        1
                    }, numberOfRows: { _ in
                        sortedItems.count
                    }, itemAtIndexPath: { indexPath in
                        return sortedItems[safe: indexPath.row]
                    }, headerTitle: { _ -> String? in
                        nil
                    }
                )
            }
        }
    }
}

extension TableDataSourceConfigurationFactory where CellItem: Aggregatable {
    static var grouped: (Reader<[CellItem], [ItemGroup<CellItem>]>) -> Self {
        { reader in
            Self { items in
                let aggregatedItems = reader.runReader(items)
                return TableDataSourceConfiguration<CellItem>(
                    numberOfSections: { () -> Int in
                        aggregatedItems.count
                    }, numberOfRows: { section -> Int in
                        aggregatedItems[safe: section]?.itemCount ?? 0
                    }, itemAtIndexPath: { indexPath in
                        aggregatedItems[safe: indexPath.section]?.item(at: indexPath.row)
                    }, headerTitle: { section -> String? in
                        aggregatedItems[safe: section]?.title
                    }
                )
            }
        }
    }
}
