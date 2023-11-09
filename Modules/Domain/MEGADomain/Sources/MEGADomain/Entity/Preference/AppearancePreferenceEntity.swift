import Foundation

public struct AppearancePreferenceEntity: Sendable {
    /// Describes the desired order to display content for a given context
    public let sortOrder: SortOrderEntity?
    /// Describes the desired view mode to present content for a given context
    public let viewModePreference: ViewModePreferenceEntity?
    
    public init(sortOrder: SortOrderEntity?, viewModePreference: ViewModePreferenceEntity?) {
        self.sortOrder = sortOrder
        self.viewModePreference = viewModePreference
    }
}
