import MEGAAssets
import MEGAL10n
import SwiftUI

public enum SearchResultsViewMode: Sendable {
    case list
    case grid
    case mediaDiscovery

    var title: String {
        switch self {
        case .list: Strings.Localizable.listView
        case .grid: Strings.Localizable.CloudDrive.ViewMode.Grid.title
        case .mediaDiscovery: Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title
        }
    }

    var icon: Image {
        switch self {
        case .list:
            MEGAAssets.Image.listSmall
        case .grid:
            MEGAAssets.Image.squares4
        case .mediaDiscovery:
            MEGAAssets.Image.photoPlaceholder
        }
    }
}
