import Foundation

struct HomeWidgetConfigEntity: Codable, Equatable, Sendable, Identifiable {
    var id: HomeWidgetType { type }

    let type: HomeWidgetType
    let isEnabled: Bool

    var isDraggable: Bool {
        type != .shortcuts && type != .accountDetails
    }

    static var defaultConfigs: [HomeWidgetConfigEntity] {
        HomeWidgetType.allCases.map { HomeWidgetConfigEntity(type: $0, isEnabled: true) }
    }
}
