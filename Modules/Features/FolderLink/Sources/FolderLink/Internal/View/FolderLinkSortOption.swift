import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import SwiftUI

enum FolderLinkSortOption {
    case nameAsc
    case nameDesc
    case sizeAsc
    case sizeDesc
    case modificationAsc
    case modificationDesc
    case labelAsc
    case labelDesc
    case favouriteAsc
    case favouriteDesc
    
    static var allFolderLinkOptions: [FolderLinkSortOption] {
        // type and order matters
        [.nameAsc, .nameDesc, .favouriteAsc, .favouriteDesc, .labelAsc, .labelDesc, .modificationAsc, .modificationDesc, .sizeAsc, .sizeDesc]
    }
}

extension FolderLinkSortOption {
    func sortOption(_ iconsByDirection: [MEGAUIComponent.SortOrder.SortDirection: Image]) -> MEGAUIComponent.SortOption {
        SortOption(
            sortOrder: sortOrder,
            title: title,
            iconsByDirection: iconsByDirection
        )
    }
    
    var sortOrder: MEGAUIComponent.SortOrder {
        switch self {
        case .nameAsc:
            SortOrder(key: .name, direction: .ascending)
        case .nameDesc:
            SortOrder(key: .name, direction: .descending)
        case .sizeAsc:
            SortOrder(key: .size, direction: .ascending)
        case .sizeDesc:
            SortOrder(key: .size, direction: .descending)
        case .modificationAsc:
            SortOrder(key: .lastModified, direction: .ascending)
        case .modificationDesc:
            SortOrder(key: .lastModified, direction: .descending)
        case .labelAsc:
            SortOrder(key: .label, direction: .ascending)
        case .labelDesc:
            SortOrder(key: .label, direction: .descending)
        case .favouriteAsc:
            SortOrder(key: .favourite, direction: .ascending)
        case .favouriteDesc:
            SortOrder(key: .favourite, direction: .descending)
        }
    }
    
    var title: String {
        switch self {
        case .nameAsc, .nameDesc:
            Strings.Localizable.Sorting.Name.title
        case .sizeAsc, .sizeDesc:
            Strings.Localizable.Sorting.Size.title
        case .modificationAsc, .modificationDesc:
            Strings.Localizable.Sorting.LastModified.title
        case .labelAsc, .labelDesc:
            Strings.Localizable.CloudDrive.Sort.label
        case .favouriteAsc, .favouriteDesc:
            Strings.Localizable.Sorting.Favourite.title
        }
    }
}

extension SortOptionsViewModel {
    static var folderLink: SortOptionsViewModel {
        let iconsByDirection: [MEGAUIComponent.SortOrder.SortDirection: Image] = [
            .ascending: MEGAAssets.Image.arrowUp,
            .descending: MEGAAssets.Image.arrowDown
        ]
        
        return SortOptionsViewModel(
            title: Strings.Localizable.sortTitle,
            sortOptions: FolderLinkSortOption.allFolderLinkOptions.map({ $0.sortOption(iconsByDirection) })
        )
    }
}
