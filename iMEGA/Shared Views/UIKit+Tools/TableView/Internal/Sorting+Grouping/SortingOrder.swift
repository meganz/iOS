import Foundation

struct SortingOrder<Item> {
    let sorted: ([Item]) -> [Item]

    static var originalOrder: Self {
        Self.init { items in
            items
        }
    }
}

extension SortingOrder where Item: Comparable {

    static var asc: Self {
        Self.init { items in
            items.sorted()
        }
    }

    static var desc: Self {
        Self.init { items in
            items.sorted().reversed()
        }
    }
}
