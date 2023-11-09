import Foundation

/// Structure that determines how the sort preference for any given folder/node is determined
public enum SortingPreferenceBasisEntity: CaseIterable {
    /// Indicates sort order should be determined by the folder they are on and use any saved sort preferences for the give folder.
    case perFolder
    /// Indicates sort order  for all folders should use saved sort preference.
    case sameForAll
}
