import Foundation

package struct HomeWidgetConfigEntity: Codable, Equatable, Sendable, Identifiable {
    package var id: HomeWidgetType { type }

    let type: HomeWidgetType
    let isEnabled: Bool

    package init(type: HomeWidgetType, isEnabled: Bool) {
        self.type = type
        self.isEnabled = isEnabled
    }

    var isDraggable: Bool {
        type != .shortcuts && type != .accountDetails
    }

    static var defaultConfigs: [HomeWidgetConfigEntity] {
        HomeWidgetType.allCases.map { HomeWidgetConfigEntity(type: $0, isEnabled: true) }
    }

    /// Decodes an array of configs, silently dropping entries whose
    /// `HomeWidgetType` raw value is no longer recognised.
    package static func safelyDecodedWidgetConfigs(from data: Data) -> [HomeWidgetConfigEntity]? {
        guard let wrappers = try? JSONDecoder().decode(
            [LossyCodable<HomeWidgetConfigEntity>].self, from: data
        ) else {
            return nil
        }
        let result = wrappers.compactMap(\.value)
        return result.isEmpty ? nil : result
    }
}

/// Wrapper that decodes each element individually, yielding `nil` on failure.
private struct LossyCodable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

extension [HomeWidgetConfigEntity] {
    func syncedWithNewWidgets() -> [HomeWidgetConfigEntity] {
        let storedTypes = Set(map(\.type))
        let missing = HomeWidgetType.allCases
            .filter { !storedTypes.contains($0) }
            .map { HomeWidgetConfigEntity(type: $0, isEnabled: true) }
        return self + missing
    }
}
