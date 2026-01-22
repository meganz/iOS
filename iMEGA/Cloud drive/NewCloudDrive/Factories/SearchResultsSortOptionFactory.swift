import MEGAAppPresentation
import MEGAUIComponent

/// A factory that returns all sort options supported by the MEGA Cloud app.
///
/// By default, these options are used everywhere, except in places that restrict the available options.
/// For example:
/// - Media Discovery mode only supports `.favourite`.
/// - Offline only supports `.name`, `.size`, and `.lastModified`.
/// - Shared Items: supported options vary by tab (Incoming, Outgoing, Links).
///
/// In these cases, define the options locally instead of using this factory.
enum SearchResultsSortOptionFactory {
    static func makeAll() -> [SortOption] {
        let keys: [MEGAUIComponent.SortOrder.Key] = [
            .name,
            .favourite,
            .label,
            .dateAdded,
            .lastModified,
            .size
        ]
        return keys.sortOptions
    }
}
