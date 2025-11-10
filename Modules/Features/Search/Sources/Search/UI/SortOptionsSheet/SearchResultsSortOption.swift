import SwiftUI

public struct SearchResultsSortOption: Identifiable {
    public var id: SortOrderEntity { sortOrder }

    public let sortOrder: SortOrderEntity
    public let title: String
    let iconsByDirection: [SortOrderEntity.Direction: Image]

    public var currentDirectionIcon: Image? {
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

    public func removeIcon() -> Self {
        .init(sortOrder: sortOrder, title: title, iconsByDirection: [:])
    }
}
