import Foundation

extension Reader where R: Collection, R.Element: Comparable {

   static func ordering(
        _ type: R.Element.Type,
        sortingItems: SortingOrder<R.Element> = .asc
    ) -> Reader<[R.Element], [R.Element]> {
        return identity(type) <|> sorting(by: sortingItems)
    }
}

extension Reader where
    R: Collection, R.Element: Aggregatable & Comparable,
    A: Collection, A.Element == ItemGroup<R.Element>,
    R.Element.Key: Comparable {

   static func aggregating(
        _ type: R.Element.Type,
        sortingSection: SortingOrder<A.Element> = .asc,
        sortingItems: SortingOrder<R.Element> = .asc
    ) -> Reader<[R.Element], [ItemGroup<R.Element>]> {
        identity(type) <|> grouping(by: sortingItems) <|> sorting(by: sortingSection)
    }
}

private func identity<Item>(_ type: Item.Type) -> Reader<[Item], [Item]> {
    Reader { $0 }
}

private func grouping<Item: Aggregatable>(_ items: [Item]) -> [ItemGroup<Item>] {
    Dictionary.init(grouping: items) { item -> AnyHashable in
        item.key
    }.map { args in
        let (_, value) = args
        return ItemGroup(items: value)
    }
}

private func grouping<Item: Aggregatable & Comparable>(asc: Bool) -> (_ items: [Item]) -> [ItemGroup<Item>] {
    let sortOrder: SortingOrder<Item> = asc ? .asc : .desc
    return grouping(by: sortOrder)
}

private func grouping<Item: Aggregatable & Comparable>(
    by sortOrder: SortingOrder<Item>
) -> (_ items: [Item]) -> [ItemGroup<Item>] {
    return { items in
        Dictionary.init(grouping: items) { item -> AnyHashable in
            item.key
        }.map { args in
            let (_, value) = args
            return ItemGroup(items: sortOrder.sorted(value))
        }
    }
}

private func sorting<Item: Comparable>(asc: Bool) -> ([Item]) -> [Item] {
    let sortOrder: SortingOrder<Item> = asc ? .asc : .desc
    return sorting(by: sortOrder)
}

private func sorting<Item: Comparable>(by sortOrder: SortingOrder<Item> = .asc) -> ([Item]) -> [Item] {
    return { items in
        return sortOrder.sorted(items)
    }
}

private func sortingStrategy<Item>(
    for type: Item.Type,
    sectionAsc: Bool,
    itemsAsc: Bool
) -> Reader<[Item], [ItemGroup<Item>]> where Item.Key: Comparable, Item: Aggregatable & Comparable {
    identity(type) <|> grouping(asc: itemsAsc) <|> sorting(asc: sectionAsc)
}

private func grouping<Item>(
    _ type: Item.Type,
    sortingSection: SortingOrder<ItemGroup<Item>> = .asc,
    sortingItems: SortingOrder<Item> = .asc
) -> Reader<[Item], [ItemGroup<Item>]> where Item.Key: Comparable, Item: Aggregatable & Comparable {
    identity(type) <|> grouping(by: sortingItems) <|> sorting(by: sortingSection)
}
