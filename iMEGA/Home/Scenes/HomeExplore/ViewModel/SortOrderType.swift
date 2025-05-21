import MEGAAssets
import MEGAL10n

enum SortOrderType: String, CaseIterable {
    case none
    case nameAscending
    case nameDescending
    case largest
    case smallest
    case newest
    case oldest
    case label
    case favourite
    
    static let allValid: [SortOrderType] = [
        .nameAscending,
        .nameDescending,
        .largest,
        .smallest,
        .newest,
        .oldest,
        .label,
        .favourite
    ]
    
    static func defaultSortOrderType(forNode node: MEGANode?) -> SortOrderType {
        return SortOrderType(megaSortOrderType: Helper.sortType(for: nil))
    }
    
    var localizedString: String {
        let key: String
        
        switch self {
        case .nameAscending:
            key = "nameAscending"
        case .nameDescending:
            key = "nameDescending"
        case .largest:
            key = "largest"
        case .smallest:
            key = "smallest"
        case .newest:
            key = "newest"
        case .oldest:
            key = "oldest"
        case .label:
            key = "Label"
        case .favourite:
            key = "Favourite"
        case .none:
            key = ""
        }
        
        return Strings.localized(key, comment: "")
    }
    
    var image: UIImage? {
        switch self {
        case .nameAscending:
            return MEGAAssets.UIImage.ascending
        case .nameDescending:
            return MEGAAssets.UIImage.descending
        case .largest:
            return MEGAAssets.UIImage.largest
        case .smallest:
            return MEGAAssets.UIImage.smallest
        case .newest:
            return MEGAAssets.UIImage.newest
        case .oldest:
            return MEGAAssets.UIImage.oldest
        case .label:
            return MEGAAssets.UIImage.sortLabel
        case .favourite:
            return MEGAAssets.UIImage.sortFavourite
        case .none:
            return nil
        }
    }
    
    var megaSortOrderType: MEGASortOrderType {
        switch self {
        case .nameAscending:
            return .defaultAsc
        case .nameDescending:
            return .defaultDesc
        case .largest:
            return .sizeDesc
        case .smallest:
            return .sizeAsc
        case .newest:
            return .modificationDesc
        case .oldest:
            return .modificationAsc
        case .label:
            return .labelAsc
        case .favourite:
            return .favouriteAsc
        case .none:
            return .none
        }
    }
    
    init(megaSortOrderType: MEGASortOrderType) {
        switch megaSortOrderType {
        case .defaultAsc:
            self = .nameAscending
        case .defaultDesc:
            self = .nameDescending
        case .sizeDesc:
            self = .largest
        case .sizeAsc:
            self = .smallest
        case .modificationDesc:
            self = .newest
        case .modificationAsc:
            self = .oldest
        case .labelAsc:
            self = .label
        case .favouriteAsc:
            self = .favourite
        default:
            self = .none
        }
    }
}
