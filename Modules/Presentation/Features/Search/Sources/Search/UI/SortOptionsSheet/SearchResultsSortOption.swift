import SwiftUI

public struct SearchResultsSortOption: Identifiable {
    public var id: SortOrderEntity { sortOrder }

    let sortOrder: SortOrderEntity
    let title: String
    let iconsByDirection: [SortOrderEntity.Direction: Image]

    var currentDirectionIcon: Image? {
        iconsByDirection[sortOrder.direction]
    }

    var toggledDirectionIcon: Image? {
        iconsByDirection[sortOrder.direction.toggled()]
    }

    public init(sortOrder: SortOrderEntity, title: String, iconsByDirection: [SortOrderEntity.Direction: Image]) {
        self.sortOrder = sortOrder
        self.title = title
        self.iconsByDirection = iconsByDirection
    }

    func removeIcon() -> Self {
        .init(sortOrder: sortOrder, title: title, iconsByDirection: [:])
    }
}
