import Foundation

struct ItemGroup<Item> {
    let items: [Item]

    var itemCount: Int { items.count }

    func item(at index: Int) -> Item? {
        return items[safe: index]
    }
}

extension ItemGroup: ItemGrouping where Item: Aggregatable {

    var title: String? {
        items.first?.title
    }

    var key: AnyHashable? {
        items.first?.key
    }
}

extension ItemGroup: Equatable where Item: Equatable {}

extension ItemGroup: Comparable where Item: Comparable, Item: Aggregatable, Item.Key: Comparable {

    static func < (lhs: ItemGroup<Item>, rhs: ItemGroup<Item>) -> Bool {
        guard let leftKey = lhs.items.first?.key else {
            return false
        }

        guard let rightKey = rhs.items.first?.key else {
            return false
        }

        return leftKey < rightKey
    }
}
